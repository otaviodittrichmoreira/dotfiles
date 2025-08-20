import argparse
import sys
from g4f.client import Client


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--system-prompt",
        "-s",
        type=str,
        default="You are a helpful assistant.",
        help="The system role prompt.",
        dest="system",
    )
    parser.add_argument(
        "--user-prompt",
        "-u",
        type=str,
        default="Hi. How can you help me?",
        help="The user's prompt to the model.",
        dest="user",
    )
    parser.add_argument(
        "--assistant-prompt",
        "-a",
        type=str,
        default="",
        help="The assistant response to the model.",
        dest="assistant",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = get_args()

    client = Client()
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": args.system},
            {"role": "user", "content": args.user},
            # {"role": "assistant", "content": args.assistant},
        ],
        web_search=False,
        provider="OIVSCodeSer2"
    )
    content = response.choices[0].message.content
    sys.stdout.write(content)
    # print(f"Provider: { response.provider }")
