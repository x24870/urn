module owner::urn_utils{
    use std::string::{Self};
    use std::vector;

    const HEX_SYMBOLS: vector<u8> = b"0123456789abcdef";

    public fun u64_to_hex_string(value: u64): string::String {
        if (value == 0) {
            return string::utf8(b"0x00")
        };
        let temp: u64 = value;
        let length: u64 = 0;
        while (temp != 0) {
            length = length + 1;
            temp = temp >> 8;
        };
        to_hex_string_fixed_length(value, length)
    }

    fun to_hex_string_fixed_length(value: u64, length: u64): string::String {
        let buffer = vector::empty<u8>();

        let i: u64 = 0;
        while (i < length * 2) {
            vector::push_back(&mut buffer, *vector::borrow(&mut HEX_SYMBOLS, (value & 0xf as u64)));
            value = value >> 4;
            i = i + 1;
        };
        assert!(value == 0, 1);
        vector::append(&mut buffer, b"x0");
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }
}
    