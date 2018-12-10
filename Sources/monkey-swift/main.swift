import Foundation
import Repl

private let prompt = ">> "

print("Hello! This is the Monkey programming language!")
print("Feel free to type in commands")

let repl = Repl()
while(true) {
    print(prompt, terminator: "")
    repl.start(with: readLine() ?? "")
}
