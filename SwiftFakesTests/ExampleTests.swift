import UIKit
import XCTest
    
// StubReturnValuesDictionary?
    
class MethodInvocation {
    let name: String
    let args: [Any]
    
    init(methodName: String, args: [Any]) {
        name = methodName
        self.args = args
    }
}

class InvocationStack {
    typealias InvocationStack = [MethodInvocation]
    
    private var methodInvocations = InvocationStack()
    
    func invoke(methodName: String, args: Any...) {
        methodInvocations.append(MethodInvocation(methodName: methodName, args: args))
    }
    
    func forMethod(methodName: String) -> [MethodInvocation] {
        return methodInvocations.filter() {
            (invocation: MethodInvocation) in
            return invocation.name == methodName
        }
    }
}

class ExampleTests: XCTestCase {
    // Class under test
    class Bar {
        let foo = Foo()
        
        init(foo: Foo) {
            self.foo = foo
        }
        
        func pokeFooTwiceAndBopItOnce() {
            foo.poke("first")
            foo.bop("second")
            foo.poke("third")
        }
        
        func pokeRemoteFoo() {
            foo.asyncPoke() {
                (response: String) -> String in
                return "Foo eventually returned \(response)"
            }
        }
    }
    
    // Dependency of class under test.
    class Foo {
        func poke(arg: String) {}
        func bop(arg: String) {}
        func asyncPoke(completionHandler: (String) -> String) {}
    }
    
    // Dependency fake to inject into class under test in order to assert about interaction between class under test and its dependency
    
    class Fake_Foo: Foo {
        let calls = InvocationStack()
        
        override func poke(arg: String) {
            calls.invoke("poke", args: arg)
        }
        
        override func bop(arg: String) {
            calls.invoke("bop", args: arg)
        }
        
        override func asyncPoke(completionHandler: (String) -> String) {
            calls.invoke("asyncPoke", args: completionHandler)
        }
    }
    
    var subject: Bar!
    var foo: Fake_Foo!
    
    override func setUp() {
        super.setUp()
        
        // By reconstructing the fake for every test, we reset the method call history
        foo = Fake_Foo()
        subject = Bar(foo: foo)
    }
    
    func test_pokeFooTwiceAndBopItOnce_pokesFooTwiceAndBopsItOnce() {
        subject.pokeFooTwiceAndBopItOnce()
        
        let invocations = foo.calls.forMethod("poke")
        
        XCTAssert(invocations.count == 2)
        
        let invocationArgs1 = invocations[0].args
        let invocationArgs2 = invocations[1].args
        
        XCTAssert(invocationArgs1[0] as String == "first")
        XCTAssert(invocationArgs2[0] as String == "third")
        
        let bopInvocations = foo.calls.forMethod("bop")
        
        XCTAssert(bopInvocations[0].args[0] as String == "second")
    }
    
    func test_pokeRemoteFoo_callsAsyncPokeOnFooWithTheCorrectCallback() {
        subject.pokeRemoteFoo()
        
        let invocations = foo.calls.forMethod("asyncPoke")
        
        XCTAssert(invocations.count == 1)
        
        let invocationCallback = invocations[0].args[0] as (String ) -> String
        let callbackResult = invocationCallback("FAKE RESULT")
        
        XCTAssert(callbackResult == "Foo eventually returned FAKE RESULT")
    }
}