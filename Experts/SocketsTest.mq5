#import "MyTestLib.dll"

void OnStart()
{
   int result = MyFunctions::Add(10, 20);
   Print("Result of Add: ", result);

   string message = MyFunctions::GetMessage();
   Print("Message from C#: ", message);
}