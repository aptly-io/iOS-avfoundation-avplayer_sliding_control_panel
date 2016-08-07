# An implementation on top of AV Foundation

## About

- Working device rotation (thanks to `layoutSubviews` in the `UIView` subclass, `PlayerView`)
- Play/Pause, scrub back and forward
- A seek bar (not using an animation; this is a POC for a media FW that gives no direct access to the `AVPlayer` and its `AVPlayerLayer`)
- A gradient coloured control panel that slides up and down based on a constraint animation
- Integration with FontAwesome for the player controls graphics

## Issues
It's not perfect:
- the scrubbing during playback becomes sometimes unresponsive
- the periodic times sometimes stops working; the seek bar no longer updates as it should
   (might be related to reaching the end of the content?)
- ...

## License: [MIT](https://opensource.org/licenses/MIT)

The MIT License (MIT)
Copyright 2016 [Francis Meyvis](https://aptly.io/contact)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
