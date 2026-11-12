# simdjson.st

A JSON reader and writer for Pharo 15 whose parsing is done by
[simdjson](https://github.com/simdjson/simdjson), with the API of
[NeoJSON](https://github.com/svenvc/NeoJSON):

- `SimdJSONReader` reads like `NeoJSONReader` (values, `mapClass:`, `listClass:`,
  `propertyNamesAsSymbols:`, `nextAs:` and the mappings), but is strict RFC 8259:
  what NeoJSON accepts by its leniency (`01`, `1.`, a control character in a string)
  raises `SimdJSONParseError`.
- `SimdJSONWriter` writes JSON as `NeoJSONWriter` does, byte for byte, with its
  protocol and mappings.

The package `SimdJSON` needs no other project: NeoJSON need not be in the image.

## Requirements

A Pharo 15 image on a VM with the **SimdJSONPlugin**: the fork
[massimo-nocentini/pharo-vm](https://github.com/massimo-nocentini/pharo-vm), branch
`pharo-12`, builds it (`docs/SimdJSON.md` there documents the plugin and how to build it).

Without the plugin, the group `FFI` reads and writes through the FFI of the image with
**libSimdJSONFFI**, the plugin's engine built as a library of its own, which the same fork
builds next to its plugins (`libSimdJSONFFI.so`, `libSimdJSONFFI.dylib`,
`SimdJSONFFI.dll`). Put the library next to the VM or the image, or name it:

```smalltalk
SimdJSONLibrary libraryPath: '/path/to/libSimdJSONFFI.so'.
SimdJSONReader backend. "#plugin, #ffi or nil"
```

It reads the same values and writes the same text: reading takes 2 to 3 times the
plugin's time, 7 to 40 times less than NeoJSON's; writing 1 to 3 times the plugin's time,
2 to 11 times less than NeoJSON's.

## Loading

Everything: the reader and writer, their tests, and the tests against NeoJSON (which
load NeoJSON with its tests):

```smalltalk
Metacello new
	baseline: 'SimdJSON';
	repository: 'github://massimo-nocentini/simdjson.st:master/src';
	load.
```

The reader and writer alone:

```smalltalk
Metacello new
	baseline: 'SimdJSON';
	repository: 'github://massimo-nocentini/simdjson.st:master/src';
	load: 'Core'.
```

With their own tests, without NeoJSON:

```smalltalk
Metacello new
	baseline: 'SimdJSON';
	repository: 'github://massimo-nocentini/simdjson.st:master/src';
	load: #( 'Core' 'Tests' ).
```

| Group | Packages |
| --- | --- |
| `Core` | `SimdJSON` |
| `Tests` | `SimdJSON-Tests` |
| `FFI` | `SimdJSON-FFI`: the reader and the writer without the plugin, through libSimdJSONFFI |
| `FFITests` | `SimdJSON-FFI-Tests` |
| `NeoTests` | `SimdJSON-NeoTests`, with NeoJSON (its groups `core` and `tests`) |
| `default` | all of the above |

## Running the tests

From the Test Runner, or headless:

```sh
pharo --headless Pharo.image --no-default-preferences test --fail-on-failure --fail-on-error SimdJSON-Tests
pharo --headless Pharo.image --no-default-preferences test --fail-on-failure --fail-on-error SimdJSON-FFI-Tests
pharo --headless Pharo.image --no-default-preferences test --fail-on-failure --fail-on-error SimdJSON-NeoTests
pharo --headless Pharo.image --no-default-preferences test --fail-on-failure --fail-on-error SimdJSON-NeoTests-Generated
pharo --headless Pharo.image --no-default-preferences eval 'SimdJSONNeoTestGenerator report'
```

`test` matches whole package names, so `SimdJSON-NeoTests` runs `SimdJSONCompatTests`
only: the generated `SJ*` classes (see below) are in `SimdJSON-NeoTests-Generated`, which
the third line runs; the last line runs them too and prints a summary.

`SimdJSON-Tests` skips the tests of the plugin itself on a VM without it.
`SimdJSON-FFI-Tests` runs the reader, mapping and writer tests again through
libSimdJSONFFI, with the plugin hidden, and is skipped without the library.

`SimdJSONSlowTests` are skipped unless the environment has `SJ_SLOW`. With `SJ_CORPUS`
naming the `jsonexamples` directory of
[simdjson-data](https://github.com/simdjson/simdjson-data), `SimdJSONCompatTests` also
read its corpus.

### The generated package

After `SimdJSON-NeoTests` is loaded, the baseline runs `SimdJSONNeoTestGenerator
generate` (a `postLoadDoIt`). It makes `SJ<name>`, a subclass of each of NeoJSON's
reader and writer test classes whose methods read and write with `SimdJSONReader` and
`SimdJSONWriter`, in the package `SimdJSON-NeoTests-Generated`. This repository does
not track that package: do not commit it. `SimdJSONNeoTestGenerator generate` remakes
the classes, and `SimdJSONNeoTestGenerator report` runs them.

## Credits and licence

`SimdJSONMapper`, `SimdJSONMapping`, `SimdJSONObjectMapping`, `SimdJSONCustomMapping`,
`SimdJSONPropertyMapping`, `SimdJSONMappingNotFound` and `SimdJSONNumberParser` are
ports of NeoJSON, Copyright (C) 2012 Sven Van Caekenberghe, under the MIT licence. Its
copyright and permission notice is in the class comment of `ManifestSimdJSON`. This
repository is under the MIT licence too: see [LICENSE](LICENSE).
