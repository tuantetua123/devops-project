import sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent.parent / "app"))
import tokens

S = "secret"

def test_roundtrip():
    assert tokens.verify(tokens.make(7, S, 45), S) == 7

def test_expired():
    t = tokens.make(7, S, 45, now=1000)
    assert tokens.verify(t, S, now=1046) is None
    assert tokens.verify(t, S, now=1044) == 7

def test_tampered():
    t = tokens.make(7, S, 45)
    sid, exp, sig = t.split(".")
    assert tokens.verify(f"8.{exp}.{sig}", S) is None
    assert tokens.verify("garbage", S) is None
    assert tokens.verify(t, "other-secret") is None
