package game

import "core:math/linalg"
import "vendor:raylib"

set_sound_position :: proc(
	listener: raylib.Camera3D,
	sound: raylib.Sound,
	position: linalg.Vector3f32,
	max_distance: f32,
) {
	// Calculate direction vector and distance between listener and sound source
	direction := position - listener.position
	distance := raylib.Vector3Length(direction)

	// Apply logarithmic distance attenuation and clamp between 0-1
	attenuation := 1 / (1 + (distance / max_distance))
	attenuation = raylib.Clamp(attenuation, 0.0, 1)

	// Calculate normalized vectors for spatial positioning
	normalized_direction := raylib.Vector3Normalize(direction)
	forward := raylib.Vector3Normalize(listener.target - listener.position)
	right := raylib.Vector3Normalize(raylib.Vector3CrossProduct(listener.up, forward))

	// Reduce volume for sounds behind the listener
	dot_product := raylib.Vector3DotProduct(forward, normalized_direction)
	if (dot_product < 0) {
		attenuation *= (1 + dot_product * 0.5)
	}

	pan := 0.5 + 0.5 * raylib.Vector3DotProduct(normalized_direction, right)
	raylib.SetSoundVolume(sound, attenuation)
	raylib.SetSoundPan(sound, pan)
}
