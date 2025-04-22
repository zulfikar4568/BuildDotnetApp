using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using BuildDotnetApp;
using FluentAssertions;

namespace BuildDotnetApp.Test
{
    [TestClass]
    public class MyMath
    {
        [TestMethod]
        public void ItShouldBe5()
        {
            BuildDotnetApp.MyMath math = new BuildDotnetApp.MyMath();
            var result = BuildDotnetApp.MyMath.Add(2, 3);
            result.Should().Be(5);
        }
    }
}
