# Soundcloud-ID3-Scraper

## How it Works.
Assuming your Filenames look like this:
```
BuntesKaos - Der Letzte Tag Auf Erden-195578401.mp3
Burn In Noise - A Message to Shankra Festival 2015-201219890.mp3
Burn In Noise - Dance Temple 09 - Boom Festival 2014-181643154.mp3
Bämmler's Proviant für'n Badestrand 2017-335101776.mp3
CIRCUIT BREAKERS _ Nano Records Series Vol.8 _ 17_01_2015-187353477.mp3
CLAPCAST #491-1988792703.mp3
Charlz Beth - Inseltape #38-961481419.mp3
Chet Faker - Thinking In Textures (Full Album)-125755178.mp3
```
the most im portant thign is the Track id with a `-` infront of it, e.g. `-195578401` and there must be somethinginfornt of it even if it is just `track-195578401`

### Start Parameters
| Parameter | Mandatory | Description |
| --- | --- | --- |
|-MusicPath| x | Path to music e.g. `/data/music` |
|-$SoundcloudClient_ID| x | SoundCloud Client ID get it from browser session is easily findable |