shader_type canvas_item;

uniform float no_normal : hint_range(0.0,1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(1.0);
uniform float tint_amt : hint_range(0.0,1.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_width : hint_range(0, 32) = 0.0;

void vertex() {
	if (outline_width>0.0) {
		VERTEX += (UV * 2.0 - 1.0) * outline_width;
	}
}

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D tex, float width) {
	for (float x = -ceil(width); x <= ceil(width); x++) {
		float offset = floor(sqrt(pow(width + 0.5, 2) - x * x));

		for (float y = -ceil(offset); y <= ceil(offset); y++) {
			vec2 xy = uv + texture_pixel_size * vec2(x, y);

			if ((xy == clamp(xy, vec2(0.0), vec2(1.0)) && texture(tex, xy).a > 0.0)) {
				return true;
			}
		}
	}
	return false;
}

void fragment() {
	vec2 uv = UV;

	if (outline_width>0.0) {
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(outline_width * 2.0));

		uv = (uv - texture_pixel_size * outline_width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;

		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR.a = 0.0;
		} else {
			COLOR = texture(TEXTURE, uv);
			NORMAL_MAP=texture(NORMAL_TEXTURE, uv).xyz;
		}
	} else {
		COLOR = texture(TEXTURE, uv);
	}

	if ((outline_width>0.0) && (COLOR.a <= 0.0) && !hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE, outline_width/4.0) && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE, outline_width)) {
		COLOR.rgb = outline_color.rgb;
		COLOR.a = 1.0;
		NORMAL=vec3(0.0,0.0,-1.0);
	} else if (tint_amt>0.0){
		COLOR.rgb = mix(COLOR.rgb,tint_color.rgb,tint_amt);
	}
}

void light() {
	if (NORMAL==vec3(0.0,0.0,-1.0)) {
		LIGHT=vec4(1.0,1.0,1.0,1.0);
	}
	else{
		float cNdotL = max(no_normal, dot(NORMAL, LIGHT_DIRECTION));
		LIGHT += LIGHT_COLOR * COLOR * cNdotL * LIGHT_ENERGY;
	}
}
