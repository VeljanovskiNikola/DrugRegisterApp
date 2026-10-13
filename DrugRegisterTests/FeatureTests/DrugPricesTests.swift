import Testing
@testable import DrugRegister

struct DrugPricesTests {

    @Test
    func noPriceAtAllIsEmpty() {
        let prices = Drug.Prices(wholesaleExVat: nil, retailWithVat: nil, reference: nil)

        #expect(prices.isEmpty)
    }

    @Test
    func anyOnePriceIsNotEmpty() {
        #expect(Drug.Prices(wholesaleExVat: 34, retailWithVat: nil, reference: nil).isEmpty == false)
        #expect(Drug.Prices(wholesaleExVat: nil, retailWithVat: 44.1, reference: nil).isEmpty == false)
        #expect(Drug.Prices(wholesaleExVat: nil, retailWithVat: nil, reference: 17.74).isEmpty == false)
    }

    /// Zero is a price the register sent, not a missing one.
    @Test
    func zeroIsAPrice() {
        #expect(Drug.Prices(wholesaleExVat: 0, retailWithVat: nil, reference: nil).isEmpty == false)
    }
}
