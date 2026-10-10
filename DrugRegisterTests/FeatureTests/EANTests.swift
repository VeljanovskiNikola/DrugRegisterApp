import Testing
@testable import DrugRegister

/// The API accepts 8 to 14 digits for `ean` and answers 400 to anything else.
struct EANTests {

    @Test(arguments: ["5310090003085", "96385074", "12345678901234"])
    func validCodesAreKept(code: String) {
        #expect(EAN.normalized(code) == code)
    }

    @Test
    func spacesAroundTheCodeAreRemoved() {
        #expect(EAN.normalized(" 5310090003085\n") == "5310090003085")
    }

    @Test(arguments: ["", "1234567", "123456789012345", "531009000308A", "5310 090003085", "５３１００９０００３０８５"])
    func invalidCodesAreRejected(code: String) {
        #expect(EAN.normalized(code) == nil)
    }
}
