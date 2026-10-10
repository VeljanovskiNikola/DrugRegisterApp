#if DEBUG
import Foundation
import UIKit

// Sample data for previews and tests. Not part of the release build.

extension Drug {
    static func make(
        id: String = "51071",
        name: String = "AMLODIPIN",
        nameCyrillic: String = "АМЛОДИПИН",
        genericName: String = "amlodipine",
        atcCode: String = "C08CA01",
        form: String = "таблета",
        strength: String = "5 mg",
        dispensing: Dispensing = .prescription,
        productType: ProductType = .generic,
        manufacturers: String = "РЕПЛЕК ФАРМ ДООЕЛ СКОПЈЕ, Скопје, Р. Северна Македонија"
    ) -> Drug {
        Drug(
            id: id,
            detailUrl: URL(string: "https://lekovi.zdravstvo.gov.mk/drugsregister/detailview/\(id)")!,
            nameLatin: name,
            nameCyrillic: nameCyrillic,
            genericName: genericName,
            atcCode: atcCode,
            extendedAtcCode: "C08CA01001",
            ean: "5310090003085",
            pharmaceuticalForm: form,
            strength: strength,
            packaging: "20 таблети (блистер 2 х 10)/кутија",
            composition: "1 таблета содржи:\nамлодипин бесилат . . . 7 mg\n(еквивалентен на 5 mg амлодипин)",
            dosage: "1 х 5-10 mg на ден (max.10 mg на ден).",
            dispensing: dispensing,
            productType: productType,
            specialWarning: nil,
            specialistRecommendation: "R",
            manufacturers: manufacturers,
            manufacturingSites: nil,
            marketingAuthorizationHolder: "РЕПЛЕК ФАРМ ДООЕЛ СКОПЈЕ",
            authorization: Authorization(
                number: "11-6470/2",
                issuedDate: Date(dateOnly: "2019-10-17"),
                expiryDate: nil,
                renewalDate: nil
            ),
            prices: Prices(wholesaleExVat: 34, retailWithVat: 44.1, reference: 17.74),
            isOnPositiveList: true,
            fundCode: "976423",
            hasBraille: true,
            hasVariations: false,
            documents: Documents(
                smpcUrl: URL(string: "https://lekovi.zdravstvo.gov.mk/drugsregister.detaileddrugsregistercomponent:downloadguide/\(id)?t:ac=detailview/\(id)"),
                patientLeafletUrl: URL(string: "https://lekovi.zdravstvo.gov.mk/drugsregister.detaileddrugsregistercomponent:downloadreport/\(id)?t:ac=detailview/\(id)"),
                labelUrl: nil
            )
        )
    }

    static let sample = Drug.make()

    /// A realistic looking list for previews. The manufacturer is a placeholder, not a real company.
    static let previewList: [Drug] = {
        let maker = "ПРИМЕР ФАРМ ДООЕЛ, Скопје, Р. Северна Македонија"
        return [
            make(id: "1", name: "PARACETAMOL", nameCyrillic: "ПАРАЦЕТАМОЛ", genericName: "paracetamol",
                 atcCode: "N02BE01", strength: "500 mg", dispensing: .otcGeneralSale, manufacturers: maker),
            make(id: "2", name: "IBUPROFEN", nameCyrillic: "ИБУПРОФЕН", genericName: "ibuprofen",
                 atcCode: "M01AE01", form: "филм-обложена таблета", strength: "400 mg",
                 dispensing: .otcPharmacy, manufacturers: maker),
            make(id: "3", name: "AMOXICILLIN", nameCyrillic: "АМОКСИЦИЛИН", genericName: "amoxicillin",
                 atcCode: "J01CA04", form: "капсула, тврда", strength: "500 mg", manufacturers: maker),
            make(id: "4", name: "AMLODIPIN", manufacturers: maker),
            make(id: "5", name: "METFORMIN", nameCyrillic: "МЕТФОРМИН", genericName: "metformin",
                 atcCode: "A10BA02", form: "филм-обложена таблета", strength: "850 mg", manufacturers: maker),
            make(id: "6", name: "OMEPRAZOL", nameCyrillic: "ОМЕПРАЗОЛ", genericName: "omeprazole",
                 atcCode: "A02BC01", form: "гастрорезистентна капсула, тврда", strength: "20 mg",
                 manufacturers: maker),
            make(id: "7", name: "ATORVASTATIN", nameCyrillic: "АТОРВАСТАТИН", genericName: "atorvastatin",
                 atcCode: "C10AA05", form: "филм-обложена таблета", strength: "20 mg", manufacturers: maker),
            make(id: "8", name: "CETIRIZIN", nameCyrillic: "ЦЕТИРИЗИН", genericName: "cetirizine",
                 atcCode: "R06AE07", form: "филм-обложена таблета", strength: "10 mg",
                 dispensing: .otcPharmacy, manufacturers: maker),
        ]
    }()
}

extension DrugPage {
    /// A fake page. IDs count up across pages: page 1 has "1"..."20", page 2 has "21"..."40".
    static func make(page: Int, limit: Int, total: Int) -> DrugPage {
        let first = (page - 1) * limit
        let count = max(0, min(limit, total - first))
        let drugs = (0..<count).map { offset in
            Drug.make(id: String(first + offset + 1), name: "DRUG \(first + offset + 1)")
        }
        let totalPages = max(1, (total + limit - 1) / limit)
        return DrugPage(
            data: drugs,
            pagination: Pagination(page: page, limit: limit, total: total, totalPages: totalPages)
        )
    }
}

extension RegisterMeta {
    static let sample = RegisterMeta(
        source: URL(string: "https://lekovi.zdravstvo.gov.mk/drugsregister")!,
        scrapedDate: Date(dateOnly: "2026-09-27")!,
        currency: "MKD",
        count: 4119,
        apiVersion: "v1",
        fullDatasetPath: "/data/drug-register.json"
    )
}

extension Data {
    /// A blank one-page A4 PDF, for previews and tests.
    static let samplePDF: Data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)).pdfData { context in
        context.beginPage()
    }
}

/// Used by previews and tests. No network.
struct StubDrugService: DrugService {
    var searchHandler: @Sendable (DrugQuery, Int, Int) async throws -> DrugPage = { _, page, limit in
        DrugPage.make(page: page, limit: limit, total: 45)
    }
    var metaResult: Result<RegisterMeta, any Error> = .success(.sample)
    var drugHandler: @Sendable (String) async throws -> Drug = { id in Drug.make(id: id) }
    var documentHandler: @Sendable (URL) async throws -> Data = { _ in Data.samplePDF }

    func search(_ query: DrugQuery, page: Int, limit: Int) async throws -> DrugPage {
        try await searchHandler(query, page, limit)
    }

    func meta() async throws -> RegisterMeta {
        try metaResult.get()
    }

    func drug(id: String) async throws -> Drug {
        try await drugHandler(id)
    }

    func document(at url: URL) async throws -> Data {
        try await documentHandler(url)
    }

    /// Returns `Drug.previewList` for any search, on one page.
    static let preview = StubDrugService(searchHandler: { _, page, limit in
        let drugs = page == 1 ? Drug.previewList : []
        return DrugPage(
            data: drugs,
            pagination: .init(page: page, limit: limit, total: Drug.previewList.count, totalPages: 1)
        )
    })
}
#endif
