#!/home/otavio/.venvs/my-env/bin/python
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
        "--provider",
        "-p",
        type=str,
        default="OIVSCodeSer2",
        help="The model provider",
        nargs="?",
    )
    parser.add_argument(
        "--model",
        "-m",
        type=str,
        nargs="?",
        default="gpt-4o-mini",
        help="The ChatBot model.",
    )
    parser.add_argument(
        "--web-search",
        "-ws",
        action="store_true",
        help="Wether to seach on the web for the response.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = get_args()

    client = Client()
    response = client.chat.completions.create(
        model=args.model,
        messages=[
            {"role": "system", "content": args.system},
            {"role": "user", "content": args.user},
        ],
        web_search=args.web_search,
        provider=args.provider,
    )
    content = response.choices[0].message.content
    sys.stdout.write(content)
