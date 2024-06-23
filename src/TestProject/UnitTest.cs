namespace TestProject;
using Project;

public class UnitTest
{
    [Fact]
    public void Test1()
    {
        // Arrange

        // Act
        var result = Class.SayHello("Template");

        // Assert
        Assert.Equal("Hello, Template!", result);
    }
}