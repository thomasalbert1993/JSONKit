# JSONKit

A lightweight, type-safe JSON toolkit for Swift. JSONKit models any valid JSON
value as a Swift enum, provides ergonomic construction from native literals,
throwing typed accessors, `Codable` support, and convenient conversions to and
from Foundation and Core Data storable representations.

## Features

- **Type-safe JSON model** — `JSONValue` mirrors the JSON data model (null,
  bool, number, string, array, object).
- **Ergonomic construction** — build JSON directly from Swift literals and
  collections via `JSONValueConvertible`.
- **Throwing typed accessors** — read values by key with clear, descriptive
  errors when a value is missing or has the wrong type.
- **`Codable` conformance** — encode and decode `JSONValue` with the standard
  `JSONEncoder`/`JSONDecoder`.
- **`RawRepresentable` bridging** — convert to and from Foundation
  (`Any`/`[String: Any]`) representations, correctly distinguishing the numbers
  `0`/`1` from booleans.
- **Model mapping** — map JSON objects onto your own types with the
  `JSONInitializable` / `JSONEncodable` / `JSONDecodable` protocols.
- **ISO 8601 dates** — parse and format dates, including microsecond-precise
  fractional seconds.
- **Core Data interop** — convert values into Core Data storable types.
- **Sendable** — `JSONValue` is `Hashable` and `Sendable`.

## Requirements

- Swift 6.3+
- Any Apple platform with Foundation.

## Installation

Add JSONKit to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/thomasalbert1993/JSONKit.git", from: "1.0.0"),
],
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["JSONKit"]
),
```

## Usage

### The `JSONValue` type

`JSONValue` is an `indirect enum` that represents any JSON value:

```swift
import JSONKit

let value: JSONValue = .object([
    "id": .number(1),
    "name": .string("Alice"),
    "active": .bool(true),
    "tags": .array([.string("swift"), .string("json")]),
    "deletedAt": .null,
])
```

`JSONObject` is a convenience alias for `[String: JSONValue]`.

### Building JSON from Swift literals

Thanks to `JSONValueConvertible`, native Swift types convert to `JSONValue`
automatically:

```swift
let value: JSONValue = ["a", "b", "c"].jsonValue          // .array([...])
let object: JSONValue = ["name": "Alice", "age": 30].jsonValue
```

The following types conform out of the box: `JSONValue`, `NSNull`, `Bool`,
`Int` (stored as `.number`), `Double`, `String`, arrays of convertibles, and
dictionaries of convertibles.

> **Note:** You should not conform any additional types to
> `JSONValueConvertible`.

The `JSONObject` initializer also lets you express `null` naturally with Swift
optionals — `nil` values become `.null`:

```swift
let object = JSONObject([
    "a": 1,
    "b": nil,        // becomes .null
    "c": "x",
])
```

### Typed accessors

Read values from a `JSONObject` with throwing accessors that validate types:

```swift
let id     = try object.int(forKey: "id")
let name   = try object.string(forKey: "name")
let active = try object.bool(forKey: "active")
let tags   = try object.stringArray(forKey: "tags")
```

Optional variants return `nil` when the key is missing or its value is `null`:

```swift
let nickname = try object.optionalString(forKey: "nickname")   // String?
let scores   = try object.optionalIntArray(forKey: "scores")   // [Int]?
```

Accessors exist for `bool`, `int`, `double`, `string`, `object`, arrays of
each, dates, and their optional counterparts. Reading a value with the wrong
type throws a descriptive `JSONError`.

You can also read typed values directly off a `JSONValue`:

```swift
let flag = try JSONValue.bool(true).boolValue     // true
let n    = try JSONValue.number(42).intValue      // 42
```

Booleans and the numbers `0`/`1` are interchangeable where sensible, and
`intValue` only accepts non-fractional numbers.

### `RawRepresentable` enums

Decode enums backed by `String`, `Int`, or `Double`:

```swift
enum Status: String { case active, inactive }

let status: Status = try object.rawRepresentable(forKey: "status")
let optional: Status? = try object.optionalRawRepresentable(forKey: "status")
```

### Mapping to your own models

Conform your types to `JSONInitializable` to build them from JSON:

```swift
struct User: JSONInitializable {
    let id: Int
    let name: String

    init(from content: JSONObject) throws {
        id = try content.int(forKey: "id")
        name = try content.string(forKey: "name")
    }
}

let user: User = try object.object(forKey: "user")
let users: [User] = try object.objectArray(forKey: "users")

// Or from a JSONObject directly:
let user2 = try object.to(User.self)
let user3: User = try object.instance()
```

Use `JSONEncodable` for the reverse direction, and the `JSONConvertible`
alias (`JSONEncodable & JSONDecodable`) when a type does both.

### Codable

`JSONValue` conforms to `Codable`, so it works with the standard encoders:

```swift
let data = try JSONEncoder().encode(value)
let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
```

### Parsing and serializing

```swift
// Decode a JSONObject from raw Data:
let object = try JSONObject(data: data)

// Serialize back to a String (optionally pretty-printed):
let string = try object.serialized(prettyPrinted: true)

// Convert an existing [String: Any] into a JSONObject:
let json = try someDictionary.toJSON()
```

### Comparing values

Default equality is exact and order-sensitive. To compare arrays while ignoring
order and duplicates, use `isEqual(to:handleArraysAsSets:)`:

```swift
let a: JSONValue = .array([.number(1), .number(2)])
let b: JSONValue = .array([.number(2), .number(1)])

a == b                                          // false
a.isEqual(to: b, handleArraysAsSets: true)      // true
```

### Working with `null`

```swift
JSONValue.null.nullAsNil                 // nil
JSONValue.string("x").nullAsNil          // .string("x")
JSONValue.optionalString(nil)            // .null
someValue.when(condition)                // someValue or .null
object.removingNullValues()              // drops all .null entries
```

### ISO 8601 dates

Date accessors parse ISO 8601 strings automatically, choosing the right format
based on the string's contents (date only, date-time, or fractional seconds):

```swift
let date = try object.date(forKey: "createdAt")
let dates = try object.dateArray(forKey: "timestamps")
```

Three shared formatters are available directly:

```swift
ISO8601DateFormatter.dateFormatter                // full date, no time
ISO8601DateFormatter.dateTimeFormatter            // date + time
ISO8601DateFormatter.dateTimeFractionalFormatter  // microsecond precision
```

For microsecond precision beyond the default millisecond support, use
`MicroSecondISO8601DateFormatter`.

### Core Data interop

Convert values into Core Data storable representations:

```swift
let storable = value.coreDataStorable          // Any
let objectStorable = object.coreDataStorable   // [String: Any]
```

## Error handling

Failed lookups and conversions throw `JSONError`:

- `.invalidValue(_:expected:)` — a value has an unexpected type.
- `.invalidValue(forKey:expected:in:)` — a keyed value has an unexpected type.
- `.missingOrNullValue(forKey:in:)` — a required key is missing or `null`.
- `.unableToSerializeObject(_:)` — serialization failed.
- `.unableToParseRawValue` — a `RawRepresentable` or dictionary conversion failed.

Date parsing throws `ISO8601DateFormatterError.invalidDate(_:)`.

## Testing

The package includes a test suite built with the Swift `Testing` framework.
Run it with:

```sh
swift test
```

## License

JSONKit is available under the MIT license. See the [LICENSE](LICENSE) file for
details.
