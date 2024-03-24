pub const Pixel = struct {
    red: u8,
    green: u8,
    blue: u8,
    alpha: u8,
};

pub const RgbaImage = struct {
    width: usize,
    height: usize,
    pixels: []Pixel,
};
