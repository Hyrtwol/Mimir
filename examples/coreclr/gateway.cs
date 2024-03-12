/*
to build run the following in this folder:
dotnet build

the see the il code use:
ildasm gateway.dll /out=gateway.il

to re-compile use:
ilasm gateway.il /dll /output=gateway_il.dll
*/
using System;
using System.Runtime.InteropServices;

public delegate bool UnmanagedCallbackDelegate(string funcName, string jsonArgs);

public static class Gateway
{
    public static string Bootstrap()
    {
        return "Bootstrap!";
    }

    public static double Plus(double x, double y)
    {
        return x + y;
    }

    unsafe public static double Sum(double* x, int n)
    {
        double sum = 0;
        for (var i = 0; i < n; i++)
        {
            sum += x[i];
        }
        return sum;
    }

    unsafe public static double Sum2(double* x, int n)
    {
        var span = new Span<double>(x, n);
        return span.ToArray().Sum();
    }

	// This method is called from unmanaged code
	[return: MarshalAs(UnmanagedType.LPStr)]
	public static string ManagedDirectMethod(
		[MarshalAs(UnmanagedType.LPStr)] string funcName,
		[MarshalAs(UnmanagedType.LPStr)] string jsonArgs,
		UnmanagedCallbackDelegate dlgUnmanagedCallback)
	{
		Console.WriteLine($"ManagedDirectMethod(funcName: {funcName}, jsonArgs: {jsonArgs})");

		string strRet = null;

		try
		{
			//strRet = directCall(funcName, jsonArgs, dlgUnmanagedCallback);
			var res = dlgUnmanagedCallback?.Invoke(funcName, jsonArgs);
			strRet = $"res={res}";
		}
		catch (Exception e)
		{
			strRet = $"ERROR in \"{funcName}\" invoke:{Environment.NewLine} {e}";
			Console.WriteLine(strRet);
		}

		return strRet;
	}
}