class_name StoryData
extends RefCounted

## Original narrative content for THE PARADOX MARKET — Chapter I: The Last Harvest.
## All characters, dialogue, memories, and worldbuilding are original.

const MISSIONS: Dictionary = {
	"walk_to_farmhouse": {
		"title": "THE LAST HARVEST",
		"objective": "Walk through the cornfield to the Vance Farmhouse",
		"hint": "Use WASD to move, Shift to sprint, Mouse to look around."
	},
	"explore_farmhouse": {
		"title": "BEFORE DEPARTURE",
		"objective": "Explore the farmhouse, gather family memories, and speak with Maya",
		"hint": "Press E to open doors, inspect family keepsakes, and talk to Maya in her bedroom."
	},
	"go_to_facility": {
		"title": "HORIZON OUTPOST 09",
		"objective": "Follow the northern beacon road to the Research Facility",
		"hint": "Exit the farmhouse and head north past the cornfield clearing toward the flashing red beacons."
	},
	"investigate_anomaly": {
		"title": "THE IMPOSSIBLE SIGNAL",
		"objective": "Decode the gravitational anomaly at the Telemetry Array inside Outpost 09",
		"hint": "Open the facility airlock (E) and access the glowing central Telemetry Console."
	},
	"initiate_launch": {
		"title": "WINDOW OF DEPARTURE",
		"objective": "Initiate launch of Aethelgard IV from the Launch Control Terminal",
		"hint": "Step to the glowing Launch Terminal beside the viewport overlooking the launch pad."
	},
	"orbital_crossing": {
		"title": "BEYOND THE DUST",
		"objective": "Approach the gravitational fold beyond Saturn's orbital plane",
		"hint": "Witness the crossing."
	},
	"enter_market": {
		"title": "THE PARADOX MARKET",
		"objective": "Cross the threshold into the Paradox Market",
		"hint": "Chapter I Finale."
	}
}

const MEMORIES: Dictionary = {
	"family_porch_photo": {
		"title": "Porch Photograph — Autumn 2082",
		"subtitle": "Living Room Mantel",
		"texture": "res://assets/textures/photo_family_porch.png",
		"body": "Elias, Clara, and a three-year-old Maya standing beneath the last amber autumn before the Fusarium-9 blight rolled across the basin.\n\nClara had insisted on taking it before the dust reached the ridge. Look closely at Maya's right hand: she is clutching a pebble she swore fell from a comet.",
		"reflection": "Elias: \"Seven years ago, we still thought the dust would settle by spring.\""
	},
	"clara_letter_and_archive": {
		"title": "Clara's Note & Botanical Archive (2041)",
		"subtitle": "Kitchen Table",
		"texture": "res://assets/textures/photo_green_earth.png",
		"body": "A faded archival print of an emerald river valley rests beside a folded note in Clara's neat, hurried handwriting:\n\n\"Elias — The triage clinic called at four. Three more respiratory cases from Sector 6. Forgive me for not standing beneath the gantry with you. If I watch that engine light, I'll beg you to step off the ramp, and neither of us can afford my weakness today.\n\nBring Maya back a sky she doesn't have to filter. Come home to us. — C.\"",
		"reflection": "Elias: \"I swear to you, Clara. I won't leave you both under a grey sun.\""
	},
	"maya_star_drawing": {
		"title": "Maya's Drawing: 'Dad's Door to Green'",
		"subtitle": "Maya's Bedroom Wall",
		"texture": "res://assets/textures/drawing_maya_stars.png",
		"body": "Pinned above Maya's desk with silver telemetry tape. Wax crayon over yellowed drafting paper: the spacecraft Aethelgard IV trailing orange flame toward a golden doorway suspended in the night sky.\n\nAlong the bottom, in careful block letters: 'WHEN DAD OPENS THE DOOR, THE RAIN COMES BACK.'",
		"reflection": "Elias: \"Ten years old, and she drew a fold-gate better than half the council.\""
	},
	"maya_farm_drawing": {
		"title": "Maya's Sketch: 'The Tall Corn'",
		"subtitle": "Maya's Desk",
		"texture": "res://assets/textures/drawing_maya_corn.png",
		"body": "A bright crayon sketch of the farmhouse encircled by golden stalks and an enormous smiling sun.\n\nIn the corner, Maya drew a tiny compass rose pointing straight upward instead of north.",
		"reflection": "Elias: \"She's never seen wheat, or snow, or an ocean. Just corn and alkali wind.\""
	},
	"soil_sensor_log": {
		"title": "Field Soil Core #14 — Telemetry Readout",
		"subtitle": "Cornfield Access Track",
		"texture": "res://assets/textures/facility_signal_screen.png",
		"body": "NITROGEN: 11% (CRITICAL)\nFUSARIUM-9 SPORE DENSITY: 418 ppm\nVIABLE CROPS REMAINING: ZEA MAYS VAR. HARDENED-4\nESTIMATED BASIN COLLAPSE: 14 MONTHS\n\nSomeone scratched a margin note on the steel casing: 'Even the corn is coughing now.'",
		"reflection": "Elias: \"Fourteen months before the last stalks go brittle. We're out of time.\""
	},
	"outpost_manifest": {
		"title": "Horizon Outpost 09 — Flight Manifest",
		"subtitle": "Facility Telemetry Bay",
		"texture": "res://assets/textures/facility_signal_screen.png",
		"body": "VESSEL: AETHELGARD IV (SINGLE-OCCUPANT LONG-RANGE SURVEY)\nPILOT / PRINCIPAL PHYSICIST: DR. ELIAS VANCE\nDESTINATION: ANOMALOUS GRAVITATIONAL NODE 09-K ('THE MARKET')\n\nNOTE FROM DIRECTOR HALE: 'Our deep-space array didn't find a habitable planet, Elias. It found a doorway someone left unlocked. Decode the harmonic lock before the atmospheric storm seals the launch corridor.'",
		"reflection": "Elias: \"One pilot. One narrow storm window. Let's see what's waiting on the other side.\""
	}
}

static func get_dialogue(dialogue_id: String) -> Array:
	match dialogue_id:
		"opening_monologue":
			return [
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "2089. First the wheat turned to rust. Then the rice fields went salt-blind. Now only the stubborn pale corn holds the dirt down against the wind."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "Fourteen months left in the basin soil. Maybe less, if the western dust wall breaks early. I need to stop by the house before the launch window opens—I can't leave without saying goodbye to Maya."
				}
			]

		"maya_goodbye":
			return [
				{
					"speaker": "MAYA VANCE",
					"role": "daughter",
					"text": "You're wearing the silver flight jacket, Dad. You only wear that when the wind alarms at the Outpost turn red."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "Sharp eyes, kiddo. The upper-atmosphere dust is clearing for forty minutes. Director Hale gave us the green light."
				},
				{
					"speaker": "MAYA VANCE",
					"role": "daughter",
					"text": "Mom left early for the clinic. Before she went, she hugged me twice and wouldn't let go of my braid. She said... sometimes leaving is the only way to keep a home."
				},
				{
					"speaker": "MAYA VANCE",
					"role": "daughter",
					"text": "Is it true there's a place past the dark where people trade whole worlds? Where there's green water that doesn't taste like chalk?",
					"choices": [
						{
							"label": "Be honest: \"I don't know what's out there, Maya—only that we have to look.\"",
							"flag": "maya_response_honest",
							"reply": [
								{
									"speaker": "DR. ELIAS VANCE",
									"role": "protagonist",
									"text": "I won't lie to you, Maya. Our instruments found a bend in gravity—a doorway that shouldn't exist. Whatever is beyond it, I'm going to find a world with real rain and clean soil for you and Mom."
								},
								{
									"speaker": "MAYA VANCE",
									"role": "daughter",
									"text": "I like it better when you tell me the real math, Dad. Even when it's scary."
								}
							]
						},
						{
							"label": "Make a promise: \"Wherever that doorway leads, I'm bringing back a blue sky.\"",
							"flag": "maya_response_promise",
							"reply": [
								{
									"speaker": "DR. ELIAS VANCE",
									"role": "protagonist",
									"text": "I promise you, Maya. Out past the dust, there's a sky you won't need a respirator to breathe. I'm going to find it, and I'm coming straight back for you and Mom."
								},
								{
									"speaker": "MAYA VANCE",
									"role": "daughter",
									"text": "You always keep your promises. Even the impossible ones."
								}
							]
						}
					]
				},
				{
					"speaker": "MAYA VANCE",
					"role": "daughter",
					"text": "Here—take my brass compass. I know needles don't point north in space, okay? I read your manuals. It's not for north. It's so you remember which direction home is."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "I'll bolt it right beside the flight yoke. Look after your mother while I'm gone, Maya. Keep sketching the stars."
				},
				{
					"speaker": "MAYA VANCE",
					"role": "daughter",
					"text": "I'll watch the ridge from my window when your engines light up. Don't forget the smell of wet earth, Dad."
				}
			]

		"maya_followup":
			return [
				{
					"speaker": "MAYA VANCE",
					"role": "daughter",
					"text": "The red beacons at Outpost 09 are blinking faster, Dad. I've got the window latch closed against the dust. Go—I'll be watching the sky."
				}
			]

		"facility_arrival":
			return [
				{
					"speaker": "OUTPOST 09 — AUTOMATED LOG",
					"role": "system",
					"text": "Airlock sealed. Particulate scrubbers engaged. Welcome, Dr. Vance. Launch corridor viability: 18 minutes remaining."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "The crew already evacuated to the eastern shelters. Just Aethelgard IV on the pad... and that gravitational signal pulsing on the main array."
				}
			]

		"puzzle_solved":
			return [
				{
					"speaker": "OUTPOST 09 — TELEMETRY AI",
					"role": "system",
					"text": "Three-harmonic lock confirmed. Non-Keplerian fold vector uploaded to Aethelgard IV navigation core. Launch Terminal unlocked."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "Those aren't random gravitational waves... they're structured like an invitation. Coordinates folded into spacetime itself."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "Navigation is loaded. Time to step up to the Launch Terminal and light the engines before the dust wall swallows the pad."
				}
			]

		"launch_transmission":
			return [
				{
					"speaker": "DR. ELIAS VANCE (RADIO)",
					"role": "protagonist",
					"text": "Horizon Outpost 09, this is Aethelgard IV. Main cryo-valves open. Clamp release in three... two..."
				},
				{
					"speaker": "DR. ELIAS VANCE (RADIO)",
					"role": "protagonist",
					"text": "Maya, Clara—if you're listening on band four... keep the porch light on. Ignition!"
				}
			]

		"cosmic_entity_encounter":
			return [
				{
					"speaker": "AETHELGARD IV — FLIGHT CORE",
					"role": "system",
					"text": "Warning: External mass readings indeterminate. Light curvature exceeding 42 degrees. Local chronometer desynchronized."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "My God... the stars are bending inward like water down glass. Something is out there—and it's looking straight through the hull."
				},
				{
					"speaker": "THE THRESHOLD (FORMLESS ENTITY)",
					"role": "entity",
					"text": "A grain of iron and carbon, carried on fire from a drying husk. You tuned our chime, traveler of the grey field."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "Who—what are you? My sensors can't resolve a shape. You're speaking inside the ship's acoustic frame."
				},
				{
					"speaker": "THE THRESHOLD (FORMLESS ENTITY)",
					"role": "entity",
					"text": "Form is a courtesy lent to creatures who fear infinity. We are the Ledger between branches. Every dying world eventually knocks upon the hinge of time."
				},
				{
					"speaker": "THE THRESHOLD (FORMLESS ENTITY)",
					"role": "entity",
					"text": "Beyond this fold lies the Paradox Market—where extinct seas, unburned suns, and borrowed tomorrows change hands. Tell us, small pilot: what do you bring to trade for a living world?",
					"choices": [
						{
							"label": "\"I bring everything humanity still knows—our memory, our science, our survival.\"",
							"flag": "entity_stance_humanity",
							"reply": [
								{
									"speaker": "DR. ELIAS VANCE",
									"role": "protagonist",
									"text": "We have no gold worth anything out here. Only ten thousand years of music, mathematics, and the stubborn refusal to let our children inherit ash. Tell me the price—I'll pay it."
								},
								{
									"speaker": "THE THRESHOLD (FORMLESS ENTITY)",
									"role": "entity",
									"text": "Bold currency. Memory weighs more than stars when measured on the right scale."
								}
							]
						},
						{
							"label": "\"I have a child waiting behind a dusty window. I'll trade my own years if I have to.\"",
							"flag": "entity_stance_sacrifice",
							"reply": [
								{
									"speaker": "DR. ELIAS VANCE",
									"role": "protagonist",
									"text": "My daughter drew a doorway in wax crayon because she's never seen rain wash a road clean. Take my time. Take whatever of me is left—just let me find her a green earth."
								},
								{
									"speaker": "THE THRESHOLD (FORMLESS ENTITY)",
									"role": "entity",
									"text": "Time is indeed the sharpest coin minted in the Market. Remember what you offered when the bells ring."
								}
							]
						}
					]
				},
				{
					"speaker": "THE THRESHOLD (FORMLESS ENTITY)",
					"role": "entity",
					"text": "Very well, Dr. Elias Vance. Keep your brass compass close; directions here obey grief as much as gravity. The stall-doors open."
				},
				{
					"speaker": "DR. ELIAS VANCE",
					"role": "protagonist",
					"text": "Look at that... an entire city hanging between galaxies. Upside-down lanterns, oceans of light... Maya—I found the door."
				}
			]

		_:
			return []
