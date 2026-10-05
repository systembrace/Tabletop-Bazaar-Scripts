shader_type canvas_item;

void fragment() {
	if (COLOR.a>0.0){
		COLOR.rgb=vec3(0.0, 0.0, 0.0);
		COLOR.a/=2.0;
	}
}