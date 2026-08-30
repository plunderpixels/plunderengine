# Templates

This section is built for the purpose of facilitating development for shader devs. I have built a few templates for features that have and have not been tested in practice. The data is purposeful and has been extracted and provided in a fashion that makes it useful for a variety of things. *These are bare templates with what I think you **should** need.*

---

## clouds.glsl

*Cloud terrain aware build up.* - needs `mcwind.volume = true`

**Five** numbers that allow for terrain aware clouds. Data for: *where* it's going, *where* it's rising, *where* it's piling up, *where* it's being torn by wind that changes speed with height, and *how much* this cloud should differ from the one next to it. This allows for creating **thiccer** more textured clouds over jagged terrain and hills while letting the clouds thin over flat terrain.

## advect.glsl

*Fog and smoke that can flow.* - needs `mcwind.volume = true`

Fog that curls and deforms rather than floating as one mass. Offset your noise by (wind x time) and it *smears*. Offset it by a fixed amount and it *slides*. I've shown you the way out of that. You carry the volume for a bounded stretch, reset, and cross-fade the two copies out of step so it appears **seamless**. Costs two noise samples instead of one, it's well worth the price.

## heat.glsl

*Built for air that wants to behave like it's hot.*

Reads *where* fire and lava are, *how strong* they are, the *height* the column still reaches, and a gradient vector pointing the way it gets hotter. I built this feature with the initial vision of better heat shimmer and refraction, so I've left the shimmer itself to **you**.

**Point sources only.** I gate the capture on block light emission, so it finds torches, lava, campfires and fire. For ambient biome heat, Iris already publishes `temperature` and `rainfall` and needs nothing from me.