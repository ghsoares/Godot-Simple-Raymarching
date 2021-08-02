shader_type spatial;

// Raymarching constants
const float SURFACE_DST = .01;
const int MAX_STEPS = 64;
const float MAX_DISTANCE = 256f;
const float NORMAL_STEP = .001f;

varying float time;

void vertex() {
	time = TIME;
}

// Rotation matrix from angle
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

// Torus signed distance field function
float SDFTorus(vec3 p, float innerRadius, float radius) {
	vec2 q = vec2(length(p.xz) - radius, p.y);
	return length(q) - innerRadius;
}

// Sphere signed distance field function
float SDFSphere(vec3 p, float radius) {
	return length(p) - radius;
}

// Box signed distance field function
float SDFBox(vec3 p, vec3 size) {
	vec3 d = abs(p) - size;
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

// Sample the whole scene, you can mix multiple shapes here
float Scene(vec3 pos) {
	// Torus
	float dst = SDFTorus(pos, .5f, 2f);
	
	// Rotating spheres
	vec3 spOff1 = vec3(cos(time * 3.1415), 0f, sin(time * 3.1415)) * 2f;
	vec3 spOff2 = vec3(cos((time + 1f) * 3.1415), 0f, sin((time + 1f) * 3.1415)) * 2f;
	dst = min(dst, SDFSphere(pos + spOff1, 1f));
	dst = min(dst, SDFSphere(pos + spOff2, 1f));
	
	// Warping box
	vec3 boxPos = pos;
	boxPos.z += cos(boxPos.y * 3.1415 * .5f) * .5f - 1f;
	boxPos = rotateY(boxPos.y * 3.1415 * .2f) * boxPos;
	dst = min(dst, SDFBox(boxPos, vec3(1f, 4f, 1f)));
	
	return dst;
}

// The actual raymarching function
float RayMarch(vec3 ro, vec3 rd) {
	float d = 0f;
	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 pos = ro + rd * d;
		float sceneDst = Scene(pos);
		
		d += sceneDst;
		
		// Only stop if distance is higher than MAX_DISTANCE or sampled distance
		// is less that surface threshold
		if (d > MAX_DISTANCE || abs(sceneDst) <= SURFACE_DST) break;
	}
	return d;
}

// Sample the world normal in the contact position
vec3 Normal(vec3 pos) {
	float d = Scene(pos);
	vec2 e = vec2(NORMAL_STEP, 0.0);
	vec3 n = d - vec3(
		Scene(pos - e.xyy),
		Scene(pos - e.yxy),
		Scene(pos - e.yyx));
	return normalize(n);
}

void fragment() {
	// Get the pixel world coordinates
	vec3 world = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Get the camera position
	vec3 camera = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	// Raymarching direction
	vec3 dir = normalize(world - camera);
	
	// Starts just a bit off the mesh surface
	vec3 ro = world - dir * SURFACE_DST;
	vec3 rd = dir;
	
	// Raymarch
	float d = RayMarch(ro, rd);
	// Set the world position from the raymarching output
	world = ro + rd * d;
	
	if (d >= MAX_DISTANCE) discard;
	
	// Samples world normal
	vec3 n = Normal(world);
	// Set the local normal relative to the view
	NORMAL = (INV_CAMERA_MATRIX * vec4(n, 0f)).xyz;
	
	// Depth calculation, this makes possible for other meshes intersect
	// properly with the geometry
	vec4 ndc = PROJECTION_MATRIX * INV_CAMERA_MATRIX * vec4(world, 1f);
	float depth = (ndc.z / ndc.w) * .5f + .5f;
	DEPTH = depth;
}