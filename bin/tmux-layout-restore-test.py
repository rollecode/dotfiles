# Self-check for the command tmux-layout-restore types into a session.
import importlib.machinery, importlib.util, os, tempfile
path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tmux-layout-restore")
loader = importlib.machinery.SourceFileLoader("restore", path)
spec = importlib.util.spec_from_loader("restore", loader)
r = importlib.util.module_from_spec(spec); loader.exec_module(r)
r.CLAUDE_IDS = tempfile.mkdtemp()
open(os.path.join(r.CLAUDE_IDS, "lobby"), "w").write("abc-123\n")

def lc(session, cmd, argv): return r.launch_command({"session": session, "cmd": cmd, "argv": argv})

assert lc("lobby", "claude", ["claude", "--resume"]) == "claude --resume abc-123"
assert lc("lobby", "claude", ["claude", "--resume", "irc-client"]) == "claude --resume abc-123"
assert lc("lobby", "claude", ["/x/claude", "--remote-control", "lobby", "-c"]) == "/x/claude --remote-control lobby --resume abc-123"
assert lc("lobby", "claude", ["claude", "-r", "--model", "opus"]) == "claude --model opus --resume abc-123"
assert lc("lobby", "claude", []) == "claude --resume abc-123"
assert lc("nobody", "claude", ["claude", "--resume", "x"]) == "claude --resume x"
assert lc("srv", "ssh", ["ssh", "-p", "2222", "example.com"]) == "ssh -p 2222 example.com"
assert lc("m", "sudo", ["sudo", "su", "mastodon"]) is None
assert lc("m", "bash", []) is None
print("ok")
