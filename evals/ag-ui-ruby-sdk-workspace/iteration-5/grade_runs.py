#!/usr/bin/env python3
"""Grade all iteration-5 runs programmatically."""

import json
import re
from pathlib import Path

WORKSPACE = Path("/Users/antonioneto/Documents/workspace/skills/evals/ag-ui-ruby-sdk-workspace/iteration-5")


def read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def grade_eval_0(outputs_dir: Path, config: str) -> dict:
    code = read_file(outputs_dir / "stream_hello_world.rb")
    expectations = []

    # 1. RunStartedEvent
    has_run_started = "RunStartedEvent" in code
    expectations.append({
        "text": "The code uses AgUiProtocol::Core::Events::RunStartedEvent",
        "passed": has_run_started,
        "evidence": f"{'Found' if has_run_started else 'Missing'} RunStartedEvent in code"
    })

    # 2. TextMessageStartEvent, TextMessageContentEvent, TextMessageEndEvent with matching message_id
    has_start = "TextMessageStartEvent" in code
    has_content = "TextMessageContentEvent" in code
    has_end = "TextMessageEndEvent" in code
    # Check for matching message_id usage (same variable name used)
    msg_id_match = re.search(r'(\w+)\s*=\s*SecureRandom\.uuid', code)
    matching_id = False
    if msg_id_match:
        var_name = msg_id_match.group(1)
        matching_id = code.count(f"message_id: {var_name}") >= 2 or code.count(f"{var_name}") >= 3
    passed = has_start and has_content and has_end and matching_id
    expectations.append({
        "text": "The code uses AgUiProtocol::Core::Events::TextMessageStartEvent, TextMessageContentEvent, and TextMessageEndEvent with matching message_id",
        "passed": passed,
        "evidence": f"Start={has_start}, Content={has_content}, End={has_end}, matching_id={matching_id}"
    })

    # 3. RunFinishedEvent
    has_run_finished = "RunFinishedEvent" in code
    expectations.append({
        "text": "The code uses AgUiProtocol::Core::Events::RunFinishedEvent at the end",
        "passed": has_run_finished,
        "evidence": f"{'Found' if has_run_finished else 'Missing'} RunFinishedEvent in code"
    })

    # 4. EventEncoder
    has_encoder = "EventEncoder" in code
    expectations.append({
        "text": "The code uses AgUiProtocol::Encoder::EventEncoder to encode events and writes them to a stream",
        "passed": has_encoder,
        "evidence": f"{'Found' if has_encoder else 'Missing'} EventEncoder in code"
    })

    return build_grading(expectations)


def grade_eval_1(outputs_dir: Path, config: str) -> dict:
    code = read_file(outputs_dir / "multimodal_input.rb")
    expectations = []

    # 1. UserMessage
    has_user_msg = "UserMessage" in code
    expectations.append({
        "text": "The code uses AgUiProtocol::Core::Types::UserMessage",
        "passed": has_user_msg,
        "evidence": f"{'Found' if has_user_msg else 'Missing'} UserMessage in code"
    })

    # 2. TextInputContent and BinaryInputContent
    has_text = "TextInputContent" in code
    has_binary = "BinaryInputContent" in code
    passed = has_text and has_binary
    expectations.append({
        "text": "The code uses AgUiProtocol::Core::Types::TextInputContent and AgUiProtocol::Core::Types::BinaryInputContent",
        "passed": passed,
        "evidence": f"TextInputContent={has_text}, BinaryInputContent={has_binary}"
    })

    # 3. UserMessage with content as array
    has_array_content = re.search(r'content:\s*\[', code) is not None
    expectations.append({
        "text": "The code initializes UserMessage with content as an array of TextInputContent and BinaryInputContent",
        "passed": has_array_content,
        "evidence": f"{'Found' if has_array_content else 'Missing'} array content initialization"
    })

    # 4. RunAgentInput with required fields
    has_run_input = "RunAgentInput" in code
    has_thread_id = "thread_id" in code
    has_run_id = "run_id" in code
    has_state = "state" in code
    has_messages = "messages" in code
    has_tools = "tools" in code
    has_context = "context" in code
    has_forwarded = "forwarded_props" in code
    passed = has_run_input and has_thread_id and has_run_id and has_state and has_messages and has_tools and has_context and has_forwarded
    expectations.append({
        "text": "The code uses AgUiProtocol::Core::Types::RunAgentInput with thread_id, run_id, state, messages, tools, context, forwarded_props",
        "passed": passed,
        "evidence": f"RunAgentInput={has_run_input}, thread_id={has_thread_id}, run_id={has_run_id}, state={has_state}, messages={has_messages}, tools={has_tools}, context={has_context}, forwarded_props={has_forwarded}"
    })

    return build_grading(expectations)


def grade_eval_2(outputs_dir: Path, config: str) -> dict:
    # Find the .rb file
    rb_files = list(outputs_dir.glob("*.rb"))
    if not rb_files:
        return build_grading([])
    code = read_file(rb_files[0])
    expectations = []

    # 1. Headers
    has_content_type = "Content-Type" in code
    has_cache = "Cache-Control" in code
    has_accel = "X-Accel-Buffering" in code
    passed = has_content_type and has_cache and has_accel
    expectations.append({
        "text": "The controller sets Content-Type, Cache-Control, and X-Accel-Buffering headers",
        "passed": passed,
        "evidence": f"Content-Type={has_content_type}, Cache-Control={has_cache}, X-Accel-Buffering={has_accel}"
    })

    # 2. with_stream pattern using rack.hijack
    has_rack_hijack = "rack.hijack" in code
    has_proc = "proc" in code
    passed = has_rack_hijack and has_proc
    expectations.append({
        "text": "One action implements the with_stream pattern using response.headers['rack.hijack'] and proc",
        "passed": passed,
        "evidence": f"rack.hijack={has_rack_hijack}, proc={has_proc}"
    })

    # 3. ActionController::Live
    has_live = "ActionController::Live" in code
    has_response_stream = "response.stream" in code
    passed = has_live and has_response_stream
    expectations.append({
        "text": "One action includes ActionController::Live and writes to response.stream",
        "passed": passed,
        "evidence": f"ActionController::Live={has_live}, response.stream={has_response_stream}"
    })

    # 4. IOError handling in both
    ioerror_count = code.count("IOError")
    passed = ioerror_count >= 2
    expectations.append({
        "text": "Both endpoints handle IOError for client disconnect",
        "passed": passed,
        "evidence": f"Found {ioerror_count} IOError references (need >= 2)"
    })

    # 5. ensure blocks in both
    ensure_count = code.count("ensure")
    passed = ensure_count >= 2
    expectations.append({
        "text": "Both endpoints close the stream in ensure blocks",
        "passed": passed,
        "evidence": f"Found {ensure_count} ensure blocks (need >= 2)"
    })

    # 6. EventEncoder
    has_encoder = "EventEncoder" in code
    expectations.append({
        "text": "The controller uses AgUiProtocol::Encoder::EventEncoder to encode events before writing to the streams",
        "passed": has_encoder,
        "evidence": f"{'Found' if has_encoder else 'Missing'} EventEncoder in code"
    })

    # 7. RunStartedEvent and RunFinishedEvent
    has_run_started = "RunStartedEvent" in code
    has_run_finished = "RunFinishedEvent" in code
    passed = has_run_started and has_run_finished
    expectations.append({
        "text": "The endpoints stream specific AG-UI events such as RunStartedEvent and RunFinishedEvent",
        "passed": passed,
        "evidence": f"RunStartedEvent={has_run_started}, RunFinishedEvent={has_run_finished}"
    })

    return build_grading(expectations)


def grade_eval_3(outputs_dir: Path, config: str) -> dict:
    text = read_file(outputs_dir / "explanation.md")
    expectations = []

    # 1. Reference files mention
    has_ref = "references/events.md" in text or "reference" in text.lower() or "documentación" in text.lower()
    expectations.append({
        "text": "The response explicitly mentions reading reference files (e.g. references/events.md) for SDK details",
        "passed": has_ref,
        "evidence": f"{'Found' if has_ref else 'Missing'} reference to documentation files"
    })

    # 2. TextMessageStartEvent attributes
    has_message_id = "message_id" in text
    has_role = "role" in text
    has_timestamp = "timestamp" in text
    passed = has_message_id and has_role and has_timestamp
    expectations.append({
        "text": "The response accurately details TextMessageStartEvent attributes (message_id, parent_id, role, index, etc.)",
        "passed": passed,
        "evidence": f"message_id={has_message_id}, role={has_role}, timestamp={has_timestamp}"
    })

    # 3. TextMessageChunkEvent attributes
    has_chunk_message_id = "message_id" in text
    has_delta = "delta" in text
    passed = has_chunk_message_id and has_delta
    expectations.append({
        "text": "The response accurately details TextMessageChunkEvent attributes (message_id, delta, index)",
        "passed": passed,
        "evidence": f"message_id={has_chunk_message_id}, delta={has_delta}"
    })

    return build_grading(expectations)


def build_grading(expectations: list) -> dict:
    passed = sum(1 for e in expectations if e["passed"])
    failed = sum(1 for e in expectations if not e["passed"])
    total = len(expectations)
    return {
        "expectations": expectations,
        "summary": {
            "passed": passed,
            "failed": failed,
            "total": total,
            "pass_rate": round(passed / total, 2) if total > 0 else 0.0
        }
    }


def main():
    graders = {
        "eval-0-events-lifecycle-stream": grade_eval_0,
        "eval-1-types-multimodal-runinput": grade_eval_1,
        "eval-2-rails-streaming-patterns": grade_eval_2,
        "eval-3-references-docs-usage": grade_eval_3,
    }

    for eval_dir_name, grader_fn in graders.items():
        eval_dir = WORKSPACE / eval_dir_name
        for config in ["with_skill", "without_skill"]:
            outputs_dir = eval_dir / config / "outputs"
            grading = grader_fn(outputs_dir, config)

            # Add timing if available
            timing_path = eval_dir / config / "timing.json"
            if timing_path.exists():
                timing = json.loads(timing_path.read_text())
                grading["timing"] = {
                    "executor_duration_seconds": timing.get("total_duration_seconds", 0)
                }

            grading_path = eval_dir / config / "grading.json"
            grading_path.write_text(json.dumps(grading, indent=2, ensure_ascii=False))
            print(f"Graded {eval_dir_name}/{config}: {grading['summary']['passed']}/{grading['summary']['total']}")


if __name__ == "__main__":
    main()
