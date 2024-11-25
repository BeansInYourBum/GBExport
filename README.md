This is a small Aseprite script for exporting sprites, tilesets and tilemaps in a raw binary format that can be directly used on original Game Boy hardware by including the exported file in an assembly file.

When exporting sprites the size of a sprite must be 8x8 and can either be all frames or just frames with a specific tag.
When exporting tilesets the size of a tile must be 8x8.
When exporting tilemaps the maximum size of a map is 32x32 and padding can be added to make transfering the bytes easier but for large projects this isn't recommended.
