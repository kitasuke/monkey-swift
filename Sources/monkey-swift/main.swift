import Foundation
import REPL

private let prompt = ">> "

print("Hello! This is the Monkey programming language!")
print("Feel free to type in commands")

let repl = REPL()
while(true) {
    print(prompt, terminator: "")
    repl.start(with: readLine() ?? "")
}
