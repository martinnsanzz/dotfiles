// calhelper: a tiny bridge between the terminal calendar (bin/calendar,
// bin/calendar-today) and the Mac's Calendar database through EventKit.
// The Mac syncs that database with iCloud, so events show up on the iPhone
// and events added on the iPhone show up here.
//
// install.sh compiles it to ~/.local/bin/calhelper. Every command prints JSON.
//
//   calhelper status
//   calhelper calendars
//   calhelper list <from YYYY-MM-DD> <to YYYY-MM-DD>     (to is inclusive)
//   calhelper add    --title T --start S --end E [--all-day] [--location L] [--calendar NAME]
//   calhelper update <id> <occurrence-start> [same options as add]
//   calhelper delete <id> <occurrence-start>
//
// Times are local: "2026-11-18T14:30" for timed events, "2026-11-18" for
// all-day ones (an all-day event's end is its last day, inclusive). A timed
// event whose end equals its start has no end time (the UIs show only the start).
// macOS asks once for calendar access, on behalf of the terminal app.

import EventKit
import Foundation

let store = EKEventStore()

func emit(_ obj: Any) {
    let data = try! JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
}

func fail(_ msg: String, code: Int32 = 1) -> Never {
    emit(["error": msg])
    exit(code)
}

let dayFmt: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f
}()
let timeFmt: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd'T'HH:mm"
    return f
}()

func parseDate(_ s: String) -> Date? {
    timeFmt.date(from: s) ?? dayFmt.date(from: s)
}

func statusString() -> String {
    let st = EKEventStore.authorizationStatus(for: .event)
    if #available(macOS 14.0, *) {
        switch st {
        case .fullAccess: return "granted"
        case .writeOnly: return "write-only"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "not-determined"
        default: return st.rawValue == 3 ? "granted" : "unknown"
        }
    }
    switch st {
    case .authorized: return "granted"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not-determined"
    default: return "unknown"
    }
}

/// Asks for access if macOS hasn't asked yet. Blocks until answered.
func ensureAccess() {
    if statusString() == "granted" { return }
    if statusString() == "not-determined" {
        let sem = DispatchSemaphore(value: 0)
        var ok = false
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, _ in ok = granted; sem.signal() }
        } else {
            store.requestAccess(to: .event) { granted, _ in ok = granted; sem.signal() }
        }
        sem.wait()
        if ok { return }
    }
    fail("no calendar access (\(statusString()))", code: 2)
}

func hex(_ cal: EKCalendar) -> String {
    guard let c = cal.cgColor, let comps = c.converted(
        to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil
    )?.components, comps.count >= 3 else { return "#89b4fa" }
    return String(format: "#%02x%02x%02x",
                  Int(comps[0] * 255), Int(comps[1] * 255), Int(comps[2] * 255))
}

func json(_ e: EKEvent) -> [String: Any] {
    var start = timeFmt.string(from: e.startDate)
    var end = timeFmt.string(from: e.endDate)
    if e.isAllDay {
        start = dayFmt.string(from: e.startDate)
        // EventKit ends all-day events at the next midnight (or 23:59:59).
        end = dayFmt.string(from: e.endDate.addingTimeInterval(-1))
        if end < start { end = start }
    }
    return [
        "id": e.eventIdentifier ?? "",
        "occurrence": timeFmt.string(from: e.startDate),
        "title": e.title ?? "",
        "start": start,
        "end": end,
        "allDay": e.isAllDay,
        "calendar": e.calendar.title,
        "color": hex(e.calendar),
        "location": e.location ?? "",
        "recurring": e.hasRecurrenceRules,
        "readOnly": !e.calendar.allowsContentModifications,
    ]
}

func findOccurrence(_ id: String, _ occ: String) -> EKEvent {
    guard let when = parseDate(occ) else { fail("bad occurrence time: \(occ)") }
    let pred = store.predicateForEvents(
        withStart: when.addingTimeInterval(-86400), end: when.addingTimeInterval(86400),
        calendars: nil)
    if let e = store.events(matching: pred).first(where: {
        $0.eventIdentifier == id && abs($0.startDate.timeIntervalSince(when)) < 60
    }) { return e }
    if let e = store.event(withIdentifier: id) { return e }
    fail("event not found")
}

func options(_ args: ArraySlice<String>) -> [String: String] {
    var out: [String: String] = [:]
    var it = args.makeIterator()
    while let a = it.next() {
        guard a.hasPrefix("--") else { fail("unexpected argument: \(a)") }
        let key = String(a.dropFirst(2))
        if key == "all-day" { out[key] = "1"; continue }
        if key == "timed" { out["all-day"] = "0"; continue }
        guard let v = it.next() else { fail("missing value for \(a)") }
        out[key] = v
    }
    return out
}

func apply(_ opts: [String: String], to e: EKEvent) {
    if let t = opts["title"] { e.title = t }
    if let l = opts["location"] { e.location = l }
    if let a = opts["all-day"] { e.isAllDay = a == "1" }
    if let name = opts["calendar"] {
        guard let cal = store.calendars(for: .event).first(where: {
            $0.title == name && $0.allowsContentModifications
        }) else { fail("no writable calendar named \(name)") }
        e.calendar = cal
    }
    if let s = opts["start"] {
        guard let d = parseDate(s) else { fail("bad start: \(s)") }
        e.startDate = d
    }
    if let s = opts["end"] {
        guard var d = parseDate(s) else { fail("bad end: \(s)") }
        if e.isAllDay { d = Calendar.current.date(byAdding: .day, value: 1, to: d)!.addingTimeInterval(-1) }
        e.endDate = d
    }
    if e.endDate < e.startDate { fail("the event ends before it starts") }
}

let argv = CommandLine.arguments
guard argv.count >= 2 else { fail("usage: calhelper status|calendars|list|add|update|delete") }

switch argv[1] {
case "status":
    emit(["status": statusString()])

case "calendars":
    ensureAccess()
    let def = store.defaultCalendarForNewEvents?.calendarIdentifier
    emit(store.calendars(for: .event).map {
        ["title": $0.title, "color": hex($0), "writable": $0.allowsContentModifications,
         "default": $0.calendarIdentifier == def, "source": $0.source.title]
    })

case "list":
    guard argv.count == 4, let from = dayFmt.date(from: argv[2]),
          let to = dayFmt.date(from: argv[3]) else { fail("usage: calhelper list FROM TO") }
    ensureAccess()
    let end = Calendar.current.date(byAdding: .day, value: 1, to: to)!
    let pred = store.predicateForEvents(withStart: from, end: end, calendars: nil)
    let events = store.events(matching: pred).sorted {
        ($0.isAllDay ? 0 : 1, $0.startDate) < ($1.isAllDay ? 0 : 1, $1.startDate)
    }
    emit(events.map(json))

case "add":
    ensureAccess()
    let opts = options(argv.dropFirst(2))
    guard opts["title"] != nil, opts["start"] != nil else { fail("add needs --title and --start") }
    let e = EKEvent(eventStore: store)
    guard let cal = store.defaultCalendarForNewEvents else { fail("no default calendar") }
    e.calendar = cal
    e.isAllDay = opts["all-day"] == "1"
    var o = opts
    if o["end"] == nil { o["end"] = o["start"] }
    e.startDate = parseDate(o["start"]!) ?? Date()
    e.endDate = e.startDate
    apply(o, to: e)
    do { try store.save(e, span: .thisEvent, commit: true) } catch { fail("\(error.localizedDescription)") }
    emit(json(e))

case "update":
    guard argv.count >= 4 else { fail("usage: calhelper update ID OCCURRENCE [options]") }
    ensureAccess()
    let e = findOccurrence(argv[2], argv[3])
    if !e.calendar.allowsContentModifications { fail("\(e.calendar.title) is read-only") }
    apply(options(argv.dropFirst(4)), to: e)
    do { try store.save(e, span: .thisEvent, commit: true) } catch { fail("\(error.localizedDescription)") }
    emit(json(e))

case "delete":
    guard argv.count == 4 else { fail("usage: calhelper delete ID OCCURRENCE") }
    ensureAccess()
    let e = findOccurrence(argv[2], argv[3])
    if !e.calendar.allowsContentModifications { fail("\(e.calendar.title) is read-only") }
    do { try store.remove(e, span: .thisEvent, commit: true) } catch { fail("\(error.localizedDescription)") }
    emit(["deleted": true])

default:
    fail("unknown command \(argv[1])")
}
