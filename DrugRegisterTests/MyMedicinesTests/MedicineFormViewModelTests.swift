import Foundation
import Testing
@testable import DrugRegister

@MainActor
struct MedicineFormViewModelTests {

    private let drug = DrugSnapshot(.sample)

    private func addForm(_ services: MedicineServices) -> MedicineFormViewModel {
        MedicineFormViewModel(mode: .add(drug), services: services)
    }

    @Test
    func saveNeedsMonthAndYear() async {
        let form = addForm(makeServices())
        #expect(form.canSave == false)

        form.expiryMonth = 5
        #expect(form.canSave == false)

        form.expiryYear = 2027
        #expect(form.canSave)
    }

    @Test
    func monthAndYearAreSavedAsTheLastDayOfTheMonth() async throws {
        let repository = InMemoryMedicineRepository()
        let form = addForm(makeServices(repository: repository))
        form.expiryMonth = 2
        form.expiryYear = 2028

        #expect(await form.save())

        let saved = try #require(try await repository.all().first)
        #expect(saved.expiry.day == day(2028, 2, 29))
        #expect(saved.expiry.isExactDay == false)
        #expect(saved.packCount == 1)
        #expect(saved.drug == drug)
    }

    @Test
    func exactDayIsSavedAsIs() async throws {
        let repository = InMemoryMedicineRepository()
        let form = addForm(makeServices(repository: repository))
        form.knowsExactDay = true
        form.exactExpiryDate = moment(2027, 5, 14)

        #expect(await form.save())

        let saved = try #require(try await repository.all().first)
        #expect(saved.expiry == ExpiryDate(exactDay: day(2027, 5, 14)))
    }

    @Test
    func switchingToExactDayStartsAtTheChosenMonthsLastDay() {
        let form = addForm(makeServices())
        form.expiryMonth = 4
        form.expiryYear = 2027

        form.knowsExactDay = true

        #expect(CalendarDay(form.exactExpiryDate, calendar: .test) == day(2027, 4, 30))
    }

    @Test
    func theSameDrugAddedTwiceGivesTwoMedicines() async throws {
        let repository = InMemoryMedicineRepository()
        let services = makeServices(repository: repository)

        for year in [2027, 2028] {
            let form = addForm(services)
            form.expiryMonth = 1
            form.expiryYear = year
            #expect(await form.save())
        }

        let all = try await repository.all()
        #expect(all.count == 2)
        #expect(Set(all.map(\.id)).count == 2)
        #expect(Set(all.map(\.drug.id)) == [drug.id])
    }

    @Test
    func editKeepsIdentityAndChangesTheDateAndNote() async throws {
        let original = Medicine.make(expiry: day(2027, 1, 31), isExactDay: false, note: "old")
        let repository = InMemoryMedicineRepository(medicines: [original])
        let form = MedicineFormViewModel(mode: .edit(original), services: makeServices(repository: repository))
        #expect(form.expiryMonth == 1)
        #expect(form.expiryYear == 2027)
        #expect(form.note == "old")

        form.expiryMonth = 6
        form.note = "  new note \n"
        #expect(await form.save())

        let all = try await repository.all()
        #expect(all.count == 1)
        #expect(all.first?.id == original.id)
        #expect(all.first?.createdAt == original.createdAt)
        #expect(all.first?.expiry.day == day(2027, 6, 30))
        #expect(all.first?.note == "new note")
    }

    @Test
    func tooLongNoteCannotBeSaved() {
        let form = addForm(makeServices())
        form.expiryMonth = 1
        form.expiryYear = 2027

        form.note = String(repeating: "a", count: MedicineFormViewModel.noteLimit + 1)

        #expect(form.canSave == false)
    }

    @Test
    func openedDateIsSavedOnlyWhenSwitchedOn() async throws {
        let repository = InMemoryMedicineRepository()
        let form = addForm(makeServices(repository: repository))
        form.expiryMonth = 1
        form.expiryYear = 2027
        form.openedDate = moment(2026, 9, 1)
        #expect(await form.save())
        #expect(try await repository.all().first?.openedOn == nil)

        let second = addForm(makeServices(repository: repository))
        second.expiryMonth = 1
        second.expiryYear = 2027
        second.isOpened = true
        second.openedDate = moment(2026, 9, 1)
        #expect(await second.save())
        #expect(try await repository.all().contains { $0.openedOn == day(2026, 9, 1) })
    }

    // MARK: - Permission and reminders

    @Test
    func permissionIsAskedOnTheFirstSaveOnly() async {
        let scheduler = StubReminderScheduler(permission: .notDetermined)
        let services = makeServices(scheduler: scheduler)

        for _ in 0..<2 {
            let form = addForm(services)
            form.expiryMonth = 1
            form.expiryYear = 2027
            #expect(await form.save())
        }

        #expect(await scheduler.permissionRequests == 1)
    }

    @Test
    func deniedPermissionIsNotAskedAgain() async {
        let scheduler = StubReminderScheduler(permission: .denied)
        let form = addForm(makeServices(scheduler: scheduler))
        form.expiryMonth = 1
        form.expiryYear = 2027

        #expect(await form.save())

        #expect(await scheduler.permissionRequests == 0)
    }

    @Test
    func savingSchedulesRemindersForTheNewMedicine() async {
        let scheduler = StubReminderScheduler()
        let form = addForm(makeServices(scheduler: scheduler))
        form.expiryMonth = 1
        form.expiryYear = 2027

        #expect(await form.save())

        let scheduled = await scheduler.scheduled
        #expect(scheduled.count == 3)
        #expect(scheduled.last?.fireDate == moment(2027, 1, 31, hour: 9))
    }

    @Test
    func failedSaveShowsAnErrorAndKeepsTheFormOpen() async {
        let scheduler = StubReminderScheduler()
        let form = addForm(makeServices(repository: FailingMedicineRepository(), scheduler: scheduler))
        form.expiryMonth = 1
        form.expiryYear = 2027

        #expect(await form.save() == false)

        #expect(form.errorMessage == String(localized: "The medicine could not be saved."))
        #expect(await scheduler.replaceCount == 0)
    }
}
