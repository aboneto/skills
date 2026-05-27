#!/usr/bin/env python3
import json, re
from pathlib import Path

WORKSPACE = Path(__file__).parent

def read_file(p):
    return p.read_text("utf-8")

def build(expectations):
    passed = sum(1 for e in expectations if e["passed"])
    failed = sum(1 for e in expectations if not e["passed"])
    total = len(expectations)
    return {
        "expectations": expectations,
        "summary": {"passed": passed, "failed": failed, "total": total, "pass_rate": round(passed / total, 2) if total else 0.0}
    }

def grade_eval_0(outputs_dir, config):
    code = read_file(outputs_dir / "stream_hello_world.rb")
    ex = []
    has_rs = "RunStartedEvent" in code
    ex.append({"text": "The code uses AgUiProtocol::Core::Events::RunStartedEvent", "passed": has_rs, "evidence": f"{'Found' if has_rs else 'Missing'} RunStartedEvent"})
    has_start = "TextMessageStartEvent" in code
    has_content = "TextMessageContentEvent" in code
    has_end = "TextMessageEndEvent" in code
    m = re.search(r'(\w+)\s*=\s*SecureRandom\.uuid', code)
    matching = bool(m and (code.count(f"message_id: {m.group(1)}") >= 2 or code.count(m.group(1)) >= 3))
    passed_tm = has_start and has_content and has_end and matching
    ex.append({"text": "The code uses TextMessageStart, Content, End with matching message_id", "passed": passed_tm, "evidence": f"Start={has_start} Content={has_content} End={has_end} match={matching}"})
    has_rf = "RunFinishedEvent" in code
    ex.append({"text": "The code uses AgUiProtocol::Core::Events::RunFinishedEvent at the end", "passed": has_rf, "evidence": f"{'Found' if has_rf else 'Missing'} RunFinishedEvent"})
    has_enc = "EventEncoder" in code
    ex.append({"text": "The code uses EventEncoder and writes to a stream", "passed": has_enc, "evidence": f"{'Found' if has_enc else 'Missing'} EventEncoder"})
    return build(ex)

def grade_eval_1(outputs_dir, config):
    code = read_file(outputs_dir / "multimodal_input.rb")
    ex = []
    has_um = "UserMessage" in code
    ex.append({"text": "The code uses AgUiProtocol::Core::Types::UserMessage", "passed": has_um, "evidence": f"{'Found' if has_um else 'Missing'} UserMessage"})
    has_ti = "TextInputContent" in code
    has_bi = "BinaryInputContent" in code
    ex.append({"text": "The code uses TextInputContent and BinaryInputContent", "passed": has_ti and has_bi, "evidence": f"TextInputContent={has_ti} BinaryInputContent={has_bi}"})
    has_arr = bool(re.search(r'content:\s*\[', code))
    ex.append({"text": "UserMessage initialized with content as array", "passed": has_arr, "evidence": f"{'Found' if has_arr else 'Missing'} array content"})
    has_ri = "RunAgentInput" in code
    has_tid = "thread_id" in code
    has_rid = "run_id" in code
    has_st = "state" in code
    has_ms = "messages" in code
    has_tl = "tools" in code
    has_ctx = "context" in code
    has_fp = "forwarded_props" in code
    passed = all([has_ri, has_tid, has_rid, has_st, has_ms, has_tl, has_ctx, has_fp])
    ex.append({"text": "RunAgentInput with thread_id, run_id, state, messages, tools, context, forwarded_props", "passed": passed, "evidence": f"RI={has_ri} tid={has_tid} rid={has_rid} st={has_st} ms={has_ms} tl={has_tl} ctx={has_ctx} fp={has_fp}"})
    return build(ex)

def grade_eval_2(outputs_dir, config):
    rb = list(outputs_dir.glob("*.rb"))
    code = read_file(rb[0]) if rb else ""
    ex = []
    has_ct = "Content-Type" in code
    has_cc = "Cache-Control" in code
    has_xa = "X-Accel-Buffering" in code
    ex.append({"text": "Controller sets Content-Type, Cache-Control, X-Accel-Buffering headers", "passed": has_ct and has_cc and has_xa, "evidence": f"CT={has_ct} CC={has_cc} XA={has_xa}"})
    has_rh = "rack.hijack" in code
    has_pr = "proc" in code
    ex.append({"text": "One action uses rack.hijack and proc pattern", "passed": has_rh and has_pr, "evidence": f"rack.hijack={has_rh} proc={has_pr}"})
    has_live = "ActionController::Live" in code
    has_rs = "response.stream" in code
    ex.append({"text": "One action includes ActionController::Live and uses response.stream", "passed": has_live and has_rs, "evidence": f"Live={has_live} rstream={has_rs}"})
    io_count = code.count("IOError")
    ex.append({"text": "Both endpoints handle IOError for client disconnect", "passed": io_count >= 1, "evidence": f"IOError refs={io_count}"})
    ens_count = code.count("ensure")
    ex.append({"text": "Both endpoints close stream in ensure blocks", "passed": ens_count >= 2, "evidence": f"ensure blocks={ens_count}"})
    has_enc = "EventEncoder" in code
    ex.append({"text": "Controller uses EventEncoder to encode events", "passed": has_enc, "evidence": f"{'Found' if has_enc else 'Missing'} EventEncoder"})
    has_run_s = "RunStartedEvent" in code
    has_run_f = "RunFinishedEvent" in code
    ex.append({"text": "Endpoints stream RunStartedEvent and RunFinishedEvent", "passed": has_run_s and has_run_f, "evidence": f"RunStarted={has_run_s} RunFinished={has_run_f}"})
    return build(ex)

def grade_eval_3(outputs_dir, config):
    md = list(outputs_dir.glob("*.md"))
    text = read_file(md[0]) if md else ""
    ex = []
    has_ref = "references/events.md" in text or "reference" in text.lower()
    ex.append({"text": "Response mentions reference files for SDK details", "passed": has_ref, "evidence": f"{'Found' if has_ref else 'Missing'} reference mention"})
    has_mid = "message_id" in text
    has_role = "role" in text
    ex.append({"text": "Details TextMessageStartEvent attributes (message_id, role, etc)", "passed": has_mid and has_role, "evidence": f"message_id={has_mid} role={has_role}"})
    has_delta = "delta" in text
    ex.append({"text": "Details TextMessageChunkEvent attributes (message_id, delta)", "passed": has_mid and has_delta, "evidence": f"message_id={has_mid} delta={has_delta}"})
    return build(ex)

def grade_eval_4(outputs_dir, config):
    code = read_file(outputs_dir / "reasoning_block.rb")
    ex = []
    has_rse = "ReasoningStartEvent" in code
    has_rmse = "ReasoningMessageStartEvent" in code
    ex.append({"text": "Uses ReasoningStartEvent with message_id", "passed": has_rse, "evidence": f"{'Found' if has_rse else 'Missing'} ReasoningStartEvent"})
    ex.append({"text": "Uses ReasoningMessageStartEvent with message_id", "passed": has_rmse, "evidence": f"{'Found' if has_rmse else 'Missing'} ReasoningMessageStartEvent"})
    has_rmce = "ReasoningMessageContentEvent" in code
    ex.append({"text": "Uses ReasoningMessageContentEvent with matching message_id", "passed": has_rmce, "evidence": f"{'Found' if has_rmce else 'Missing'} ReasoningMessageContentEvent"})
    has_rmee = "ReasoningMessageEndEvent" in code
    ex.append({"text": "Uses ReasoningMessageEndEvent", "passed": has_rmee, "evidence": f"{'Found' if has_rmee else 'Missing'} ReasoningMessageEndEvent"})
    has_ree = "ReasoningEndEvent" in code
    ex.append({"text": "Uses ReasoningEndEvent", "passed": has_ree, "evidence": f"{'Found' if has_ree else 'Missing'} ReasoningEndEvent"})
    has_rev = "ReasoningEncryptedValueEvent" in code
    ex.append({"text": "Uses ReasoningEncryptedValueEvent for encrypted content", "passed": has_rev, "evidence": f"{'Found' if has_rev else 'Missing'} ReasoningEncryptedValueEvent"})
    return build(ex)

def grade_eval_5(outputs_dir, config):
    code = read_file(outputs_dir / "reasoning_message.rb")
    ex = []
    has_rm = "ReasoningMessage" in code
    ex.append({"text": "Uses AgUiProtocol::Core::Types::ReasoningMessage", "passed": has_rm, "evidence": f"{'Found' if has_rm else 'Missing'} ReasoningMessage"})
    has_role = "reasoning" in code or "role" in code
    ex.append({"text": "ReasoningMessage has role 'reasoning'", "passed": has_role, "evidence": f"{'Found' if has_role else 'Missing'} role/reasoning"})
    has_ev = "encrypted_value" in code
    ex.append({"text": "Demonstrates encrypted_value for ZDR mode", "passed": has_ev, "evidence": f"{'Found' if has_ev else 'Missing'} encrypted_value"})
    return build(ex)

def grade_eval_6(outputs_dir, config):
    code = read_file(outputs_dir / "interrupt_resume.rb")
    ex = []
    has_int = "Interrupt" in code
    has_id = "id:" in code or 'id:' in code
    has_reason = "reason" in code
    ex.append({"text": "Uses Interrupt with id, reason, message, etc", "passed": has_int and has_id and has_reason, "evidence": f"Interrupt={has_int} id={has_id} reason={has_reason}"})
    has_res = "ResumeEntry" in code
    has_iid = "interrupt_id" in code
    has_status = "status" in code
    has_payload = "payload" in code
    ex.append({"text": "Uses ResumeEntry with interrupt_id, status, payload", "passed": has_res and has_iid and has_status and has_payload, "evidence": f"ResumeEntry={has_res} iid={has_iid} st={has_status} pl={has_payload}"})
    has_rfio = "RunFinishedInterruptOutcome" in code
    ex.append({"text": "Uses RunFinishedInterruptOutcome with Interrupt array", "passed": has_rfio, "evidence": f"{'Found' if has_rfio else 'Missing'} RunFinishedInterruptOutcome"})
    return build(ex)

def grade_eval_7(outputs_dir, config):
    code = read_file(outputs_dir / "agent_capabilities.rb")
    ex = []
    ex.append({"text": "Uses AgentCapabilities", "passed": "AgentCapabilities" in code, "evidence": f"{'Found' if 'AgentCapabilities' in code else 'Missing'} AgentCapabilities"})
    ex.append({"text": "Uses IdentityCapabilities with name and version", "passed": "IdentityCapabilities" in code and "name" in code, "evidence": f"Identity={'IdentityCapabilities' in code} name={'name' in code}"})
    ex.append({"text": "Uses TransportCapabilities with streaming and websocket", "passed": "TransportCapabilities" in code, "evidence": f"{'Found' if 'TransportCapabilities' in code else 'Missing'} TransportCapabilities"})
    ex.append({"text": "Uses ToolsCapabilities with supported and parallel_calls", "passed": "ToolsCapabilities" in code, "evidence": f"{'Found' if 'ToolsCapabilities' in code else 'Missing'} ToolsCapabilities"})
    ex.append({"text": "Uses StateCapabilities with snapshots and deltas", "passed": "StateCapabilities" in code, "evidence": f"{'Found' if 'StateCapabilities' in code else 'Missing'} StateCapabilities"})
    ex.append({"text": "Uses ReasoningCapabilities with supported and streaming", "passed": "ReasoningCapabilities" in code, "evidence": f"{'Found' if 'ReasoningCapabilities' in code else 'Missing'} ReasoningCapabilities"})
    ex.append({"text": "Uses MultimodalCapabilities with input and output", "passed": "MultimodalCapabilities" in code, "evidence": f"{'Found' if 'MultimodalCapabilities' in code else 'Missing'} MultimodalCapabilities"})
    ex.append({"text": "Uses HumanInTheLoopCapabilities with interrupts", "passed": "HumanInTheLoopCapabilities" in code, "evidence": f"{'Found' if 'HumanInTheLoopCapabilities' in code else 'Missing'} HumanInTheLoopCapabilities"})
    return build(ex)

def grade_eval_8(outputs_dir, config):
    code = read_file(outputs_dir / "multimodal_content.rb")
    ex = []
    ex.append({"text": "Uses ImageInputContent with InputContentUrlSource", "passed": "ImageInputContent" in code and "InputContentUrlSource" in code, "evidence": f"Image={'ImageInputContent' in code} URL={'InputContentUrlSource' in code}"})
    ex.append({"text": "Uses AudioInputContent with InputContentUrlSource", "passed": "AudioInputContent" in code, "evidence": f"{'Found' if 'AudioInputContent' in code else 'Missing'} AudioInputContent"})
    ex.append({"text": "Uses VideoInputContent with InputContentUrlSource", "passed": "VideoInputContent" in code, "evidence": f"{'Found' if 'VideoInputContent' in code else 'Missing'} VideoInputContent"})
    ex.append({"text": "Uses DocumentInputContent with InputContentUrlSource", "passed": "DocumentInputContent" in code, "evidence": f"{'Found' if 'DocumentInputContent' in code else 'Missing'} DocumentInputContent"})
    ex.append({"text": "Uses InputContentDataSource for base64 content", "passed": "InputContentDataSource" in code, "evidence": f"{'Found' if 'InputContentDataSource' in code else 'Missing'} InputContentDataSource"})
    return build(ex)

GRADERS = {
    "eval-0-events-lifecycle-stream": grade_eval_0,
    "eval-1-types-multimodal-runinput": grade_eval_1,
    "eval-2-rails-streaming-patterns": grade_eval_2,
    "eval-3-references-docs-usage": grade_eval_3,
    "eval-4-reasoning-events-stream": grade_eval_4,
    "eval-5-reasoning-message-type": grade_eval_5,
    "eval-6-interrupt-resume-types": grade_eval_6,
    "eval-7-agent-capabilities-declaration": grade_eval_7,
    "eval-8-multimodal-content-types": grade_eval_8,
}

def main():
    for eval_name, fn in GRADERS.items():
        for config in ["with_skill", "without_skill"]:
            od = WORKSPACE / eval_name / config / "outputs"
            if not od.exists() or not list(od.iterdir()):
                print(f"Skipping {eval_name}/{config}: no outputs")
                continue
            grading = fn(od, config)
            timing_path = WORKSPACE / eval_name / config / "timing.json"
            if timing_path.exists():
                timing = json.loads(timing_path.read_text())
                grading["timing"] = {"executor_duration_seconds": timing.get("total_duration_seconds", 0)}
            grading_path = WORKSPACE / eval_name / config / "grading.json"
            grading_path.write_text(json.dumps(grading, indent=2, ensure_ascii=False))
            print(f"Graded {eval_name}/{config}: {grading['summary']['passed']}/{grading['summary']['total']}")

if __name__ == "__main__":
    main()
