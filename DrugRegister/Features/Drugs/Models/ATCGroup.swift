import Foundation

/// The 14 main groups (first level) of the WHO ATC classification.
/// The API filters by ATC prefix, so the raw value is sent as `atc`.
enum ATCGroup: String, CaseIterable, Hashable, Sendable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case g = "G"
    case h = "H"
    case j = "J"
    case l = "L"
    case m = "M"
    case n = "N"
    case p = "P"
    case r = "R"
    case s = "S"
    case v = "V"

    var code: String { rawValue }

    var title: String {
        switch self {
        case .a: String(localized: "Alimentary tract and metabolism")
        case .b: String(localized: "Blood and blood forming organs")
        case .c: String(localized: "Cardiovascular system")
        case .d: String(localized: "Dermatologicals")
        case .g: String(localized: "Genito-urinary system and sex hormones")
        case .h: String(localized: "Systemic hormonal preparations")
        case .j: String(localized: "Anti-infectives for systemic use")
        case .l: String(localized: "Antineoplastic and immunomodulating agents")
        case .m: String(localized: "Musculo-skeletal system")
        case .n: String(localized: "Nervous system")
        case .p: String(localized: "Antiparasitic products")
        case .r: String(localized: "Respiratory system")
        case .s: String(localized: "Sensory organs")
        case .v: String(localized: "Various")
        }
    }
}
