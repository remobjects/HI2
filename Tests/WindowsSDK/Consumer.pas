// Positive compile-only guard: the real EC SDK supplies the AMD64 Windows context
// layout and a callable Windows DLL import. This does not claim IslandRTL/GC execution.
namespace WindowsSdkConsumer;
method ContextSize: NativeInt; public;
begin
  exit sizeOf(rtl.CONTEXT);
end;
method ReadStack(aContext: ^rtl.CONTEXT): UInt64; public;
begin
  exit aContext^.Rsp;
end;
method Tick: UInt32; public;
begin
  exit rtl.GetTickCount;
end;
end.
