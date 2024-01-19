# Atoll (modified)

Atoll is a library for generating cryptographically secure and highly random secrets.
Modified by Payton Erickson for use in Cybersecurity competitions

## Features

- High level of randomness
- Semi-Well tested
- Some dependencies
- No Input validation
- Custom seed input
- Secret sanitization (might still work)
- Include characters/words/syllables in random positions
- Exclude any undesired character/word/syllable
- **Password**:
    * Different levels (custom levels can be used as well)
    * Enable/disable character repetition
- **Passphrase**:
    * Choose between Word, Syllable or No list options to generate the passphrase
    * Custom word/syllable separator
    * Custom wordlists
    * Choose between Wordlists with capitals, random number, or both!

## Usage

download the directory into src/atoll

```go
package main

import (
    "fmt"
    "log"

    "atoll"
)

func main() {
    p := &atoll.Password{
        Length: 16,
        Levels: []int{atoll.Lower, atoll.Upper, atoll.Digit},
        Include: "a&1",
        Repeat: true,
    }
    password, err := atoll.NewSecret(p)
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println(password)
    // 1VOKM7mNA6w&oIan

    p1 := &atoll.Passphrase{
        Length: 7,
        Separator: "/",
        List: atoll.NoList,
    }
    passphrase, err := atoll.NewSecret(p1)
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println(passphrase)
    // aei/jwyjidaasres/duii/rscfiotuuckm/ydsiacf/ora/yywu
}
```

## Documentation

### Password levels

Atoll guarantees that the password will contain at least one of the characters of each level selected (except Space<sup>[1](#one)</sup>), only if the length of the password is higher than the number of levels.

1. Lowecases (a, b, c...)
2. Uppercases (A, B, C...)
3. Digits (1, 2, 3...)
4. Space
5. Special (!, $, %...)

### Passphrases options

Atoll offers ways of generating a passphrase:

- **Without** a list (*NoList*): generates random numbers that determine the word length (between 3 and 12 letters) and if the letter is either a vowel or a constant. Note that using a list makes the potential attacker job harder.

- With a **Word** list (*WordList*): random words are taken from a 18,235 long word list.
    
- With a **Syllable** list (*SyllableList*): random syllables are taken from a 10,129 long syllable list.

- And more!

### Randomness

> Randomness is a measure of the observer's ignorance, not an inherent quality of a process.

Atoll (modified) uses the "math/rand/v2" package to generate **cryptographically secure pseudo random numbers**.

### Entropy

Entropy is a **measure of the uncertainty of a system**. The concept is a difficult one to grasp fully and is confusing, even to experts. Strictly speaking, any given passphrase has an entropy of zero because it is already chosen. It is the method you use to randomly select your passphrase that has entropy. Entropy tells how hard it will be to guess the passphrase itself even if an attacker knows the method you used to select your passphrase. A passphrase is more secure if it is selected using a method that has more entropy. Entropy is measured in bits. The outcome of a single coin toss -- "heads or tails" -- has one bit of entropy. - *Arnold G. Reinhold*.

> Entropy = log2(poolLength ^ secretLength)

The French National Cybersecurity Agency (ANSSI) recommends secrets having a minimum of 100 bits when it comes to passwords or secret keys for encryption systems that absolutely must be secure. In fact, the agency recommends 128 bits to guarantee security for several years. It considers 64 bits to be very small (very weak); 64 to 80 bits to be small; and 80 to 100 bits to be medium (moderately strong).

### Keyspace

Keyspace is the set of all possible permutations of a key. On average, half the key space must be searched to find the solution.

> Keyspace = poolLength ^ secretLength

### Seconds to crack

> When calculating the seconds to crack the secret what is considered is a brute force attack. Dictionary and social engineering attacks (like shoulder surfing. pretexting, etc) are left out of consideration.

The time taken in seconds by a brute force attack to crack a secret is calculated by doing `keyspace / guessesPerSecond` where the guesses per second is 1 trillon<sup>[2](#two)</sup>.

In 2019 a record was set for a computer trying to generate every conceivable password. It achieved a rate faster than 100 billion guesses per second.

<a name="one">1</a>: If the level *Space* is used or the user includes a *space* it isn't 100% guaranteed that the space will be part of the secret, as it could be at the end or the start of the password and it would be deleted and replaced by the sanitizer.

<a name="two">2</a>: This value may be changed in the future.

## License

Atoll (modified) is licensed under the [MIT](/LICENSE) license.
