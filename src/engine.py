import json
import os

from dotenv import load_dotenv
from openai import OpenAI
from utils import JobInput

LLAMA_SERVER_PORT = os.getenv("LLAMA_ARG_PORT", "8080")

client = OpenAI(
    base_url=f'http://127.0.0.1:{LLAMA_SERVER_PORT}/v1/',
    api_key='llama-server',  # required by SDK but ignored by llama-server
)


def get_model_name():
    alias = os.getenv("LLAMA_ARG_ALIAS", "")
    if alias:
        return alias
    model_path = os.getenv("LLAMA_ARG_MODEL", "")
    if model_path:
        return os.path.splitext(os.path.basename(model_path))[0]
    return "default"


class LlamaEngine:
    def __init__(self):
        load_dotenv()
        self.model_name = get_model_name()
        print(f"LlamaEngine initialized (model: {self.model_name})")

    async def generate(self, job_input):
        model = self.model_name

        if isinstance(job_input.llm_input, str):
            openAiJob = JobInput({
                "openai_route": "/v1/completions",
                "openai_input": {
                    "model": model,
                    "prompt": job_input.llm_input,
                    "stream": job_input.stream
                }
            })
        else:
            openAiJob = JobInput({
                "openai_route": "/v1/chat/completions",
                "openai_input": {
                    "model": model,
                    "messages": job_input.llm_input,
                    "stream": job_input.stream
                }
            })

        print("Generating response for job_input:", job_input)
        print("OpenAI job:", openAiJob)

        openAIEngine = LlamaOpenAiEngine()
        generate = openAIEngine.generate(openAiJob)

        async for batch in generate:
            yield batch


class LlamaOpenAiEngine(LlamaEngine):
    def __init__(self):
        load_dotenv()
        self.model_name = get_model_name()
        print("LlamaOpenAiEngine initialized")

    async def generate(self, job_input):
        print("Generating response for job_input:", job_input)

        openai_input = job_input.openai_input

        if job_input.openai_route == "/v1/models":
            async for response in self._handle_model_request():
                yield response
        elif job_input.openai_route in ["/v1/chat/completions", "/v1/completions"]:
            async for response in self._handle_chat_or_completion_request(openai_input, chat=job_input.openai_route == "/v1/chat/completions"):
                yield response
        else:
            yield {"error": "Invalid route"}

    async def _handle_model_request(self):
        try:
            response = client.models.list()
            yield {"object": "list", "data": [model.to_dict() for model in response.data]}
        except Exception as e:
            yield {"error": str(e)}

    async def _handle_chat_or_completion_request(self, openai_input, chat=False):
        try:
            if chat:
                response = client.chat.completions.create(**openai_input)
            else:
                response = client.completions.create(**openai_input)

            if not openai_input.get("stream", False):
                yield response.to_dict()
                return

            for chunk in response:
                print("Message:", chunk)
                yield "data: " + json.dumps(chunk.to_dict(), separators=(',', ':')) + "\n\n"

            yield "data: [DONE]"
        except Exception as e:
            yield {"error": str(e)}
