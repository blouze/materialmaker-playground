shader_type spatial;
uniform float seed_variation = 0.0;
varying float elapsed_time;
varying vec3 world_camera;
varying vec3 world_position;
const int MAX_STEPS = 100;
const float MAX_DIST = 100.0;
const float SURF_DIST = 1e-3;
float rand(vec2 x) {
    return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}

vec2 rand2(vec2 x) {
    return fract(cos(mod(vec2(dot(x, vec2(13.9898, 8.141)),
						      dot(x, vec2(3.4562, 17.398))), vec2(3.14))) * 43758.5453);
}

vec3 rand3(vec2 x) {
    return fract(cos(mod(vec3(dot(x, vec2(13.9898, 8.141)),
							  dot(x, vec2(3.4562, 17.398)),
                              dot(x, vec2(13.254, 5.867))), vec3(3.14))) * 43758.5453);
}

float param_rnd(float minimum, float maximum, float seed) {
	return minimum+(maximum-minimum)*rand(vec2(seed));
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

uniform float o8100_n_rot = 15.064; // {default:0.01, label:n_rot, max:0.1, min:0, name:n_rot, step:0.001, type:named_parameter}

// https://www.shadertoy.com/view/XsX3zB
//
// The MIT License
// Copyright © 2013 Nikita Miropolskiy
// 
// ( license has been changed from CCA-NC-SA 3.0 to MIT
//
//   but thanks for attributing your source code when deriving from this sample 
//   with a following link: https://www.shadertoy.com/view/XsX3zB )
//
//
// if you're looking for procedural noise implementation examples you might 
// also want to look at the following shaders:
// 
// Noise Lab shader by candycat: https://www.shadertoy.com/view/4sc3z2
//
// Noise shaders by iq:
//     Value    Noise 2D, Derivatives: https://www.shadertoy.com/view/4dXBRH
//     Gradient Noise 2D, Derivatives: https://www.shadertoy.com/view/XdXBRH
//     Value    Noise 3D, Derivatives: https://www.shadertoy.com/view/XsXfRH
//     Gradient Noise 3D, Derivatives: https://www.shadertoy.com/view/4dffRH
//     Value    Noise 2D             : https://www.shadertoy.com/view/lsf3WH
//     Value    Noise 3D             : https://www.shadertoy.com/view/4sfGzS
//     Gradient Noise 2D             : https://www.shadertoy.com/view/XdXGW8
//     Gradient Noise 3D             : https://www.shadertoy.com/view/Xsl3Dl
//     Simplex  Noise 2D             : https://www.shadertoy.com/view/Msf3WH
//     Voronoise: https://www.shadertoy.com/view/Xd23Dh
//
//
//

// discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 XsX3zB_oct_random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

// skew constants for 3d simplex functions
const float XsX3zB_oct_F3 =  0.3333333;
const float XsX3zB_oct_G3 =  0.1666667;

// 3d simplex noise
float XsX3zB_oct_simplex3d(vec3 p) {
	 // 1. find current tetrahedron T and it's four vertices
	 // s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices
	 // x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices
	 
	 // calculate s and x
	 vec3 s = floor(p + dot(p, vec3(XsX3zB_oct_F3)));
	 vec3 x = p - s + dot(s, vec3(XsX3zB_oct_G3));
	 
	 // calculate i1 and i2
	 vec3 e = step(vec3(0.0), x - x.yzx);
	 vec3 i1 = e*(1.0 - e.zxy);
	 vec3 i2 = 1.0 - e.zxy*(1.0 - e);
	 	
	 // x1, x2, x3
	 vec3 x1 = x - i1 + XsX3zB_oct_G3;
	 vec3 x2 = x - i2 + 2.0*XsX3zB_oct_G3;
	 vec3 x3 = x - 1.0 + 3.0*XsX3zB_oct_G3;
	 
	 // 2. find four surflets and store them in d
	 vec4 w, d;
	 
	 // calculate surflet weights
	 w.x = dot(x, x);
	 w.y = dot(x1, x1);
	 w.z = dot(x2, x2);
	 w.w = dot(x3, x3);
	 
	 // w fades from 0.6 at the center of the surflet to 0.0 at the margin
	 w = max(0.6 - w, 0.0);
	 
	 // calculate surflet components
	 d.x = dot(XsX3zB_oct_random3(s), x);
	 d.y = dot(XsX3zB_oct_random3(s + i1), x1);
	 d.z = dot(XsX3zB_oct_random3(s + i2), x2);
	 d.w = dot(XsX3zB_oct_random3(s + 1.0), x3);
	 
	 // multiply d by w^4
	 w *= w;
	 w *= w;
	 d *= w;
	 
	 // 3. return the sum of the four surflets
	 return dot(d, vec4(52.0));
}

// https://www.shadertoy.com/view/XsX3zB
//
// The MIT License
// Copyright © 2013 Nikita Miropolskiy
// 
// ( license has been changed from CCA-NC-SA 3.0 to MIT
//
//   but thanks for attributing your source code when deriving from this sample 
//   with a following link: https://www.shadertoy.com/view/XsX3zB )
//
//
// if you're looking for procedural noise implementation examples you might 
// also want to look at the following shaders:
// 
// Noise Lab shader by candycat: https://www.shadertoy.com/view/4sc3z2
//
// Noise shaders by iq:
//     Value    Noise 2D, Derivatives: https://www.shadertoy.com/view/4dXBRH
//     Gradient Noise 2D, Derivatives: https://www.shadertoy.com/view/XdXBRH
//     Value    Noise 3D, Derivatives: https://www.shadertoy.com/view/XsXfRH
//     Gradient Noise 3D, Derivatives: https://www.shadertoy.com/view/4dffRH
//     Value    Noise 2D             : https://www.shadertoy.com/view/lsf3WH
//     Value    Noise 3D             : https://www.shadertoy.com/view/4sfGzS
//     Gradient Noise 2D             : https://www.shadertoy.com/view/XdXGW8
//     Gradient Noise 3D             : https://www.shadertoy.com/view/Xsl3Dl
//     Simplex  Noise 2D             : https://www.shadertoy.com/view/Msf3WH
//     Voronoise: https://www.shadertoy.com/view/Xd23Dh
//
//
//

// discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 XsX3zB_random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

// skew constants for 3d simplex functions
const float XsX3zB_F3 =  0.3333333;
const float XsX3zB_G3 =  0.1666667;

// 3d simplex noise
float XsX3zB_simplex3d(vec3 p) {
	 // 1. find current tetrahedron T and it's four vertices
	 // s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices
	 // x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices
	 
	 // calculate s and x
	 vec3 s = floor(p + dot(p, vec3(XsX3zB_F3)));
	 vec3 x = p - s + dot(s, vec3(XsX3zB_G3));
	 
	 // calculate i1 and i2
	 vec3 e = step(vec3(0.0), x - x.yzx);
	 vec3 i1 = e*(1.0 - e.zxy);
	 vec3 i2 = 1.0 - e.zxy*(1.0 - e);
	 	
	 // x1, x2, x3
	 vec3 x1 = x - i1 + XsX3zB_G3;
	 vec3 x2 = x - i2 + 2.0*XsX3zB_G3;
	 vec3 x3 = x - 1.0 + 3.0*XsX3zB_G3;
	 
	 // 2. find four surflets and store them in d
	 vec4 w, d;
	 
	 // calculate surflet weights
	 w.x = dot(x, x);
	 w.y = dot(x1, x1);
	 w.z = dot(x2, x2);
	 w.w = dot(x3, x3);
	 
	 // w fades from 0.6 at the center of the surflet to 0.0 at the margin
	 w = max(0.6 - w, 0.0);
	 
	 // calculate surflet components
	 d.x = dot(XsX3zB_random3(s), x);
	 d.y = dot(XsX3zB_random3(s + i1), x1);
	 d.z = dot(XsX3zB_random3(s + i2), x2);
	 d.w = dot(XsX3zB_random3(s + 1.0), x3);
	 
	 // multiply d by w^4
	 w *= w;
	 w *= w;
	 d *= w;
	 
	 // 3. return the sum of the four surflets
	 return dot(d, vec4(52.0));
}
vec2 sdf3d_smooth_union(vec2 d1, vec2 d2, float k) {
    float h = clamp(0.5+0.5*(d2.x-d1.x)/k, 0.0, 1.0);
    return vec2(mix(d2.x, d1.x, h)-k*h*(1.0-h), mix(d2.y, d1.y, step(d1.x, d2.x)));
}

vec2 sdf3d_smooth_subtraction(vec2 d1, vec2 d2, float k ) {
    float h = clamp(0.5-0.5*(d2.x+d1.x)/k, 0.0, 1.0);
    return vec2(mix(d2.x, -d1.x, h )+k*h*(1.0-h), d2.y);
}

vec2 sdf3d_smooth_intersection(vec2 d1, vec2 d2, float k ) {
    float h = clamp(0.5-0.5*(d2.x-d1.x)/k, 0.0, 1.0);
    return vec2(mix(d2.x, d1.x, h)+k*h*(1.0-h), mix(d1.y, d2.y, step(d1.x, d2.x)));
}

const float p_o8096_BaseColor_r = 1.000000000;
const float p_o8096_BaseColor_g = 1.000000000;
const float p_o8096_BaseColor_b = 1.000000000;
const float p_o8096_BaseColor_a = 1.000000000;
const float p_o8096_Metallic = 0.000000000;
const float p_o8096_Specular = 0.500000000;
const float p_o8096_Roughness = 0.305000000;
const float p_o8096_Emission = 0.000000000;
const float p_o8096_Normal = 0.000000000;
const float p_o8096_Alpha = 0.000000000;
const float p_o8096_AmbientOcclusion = 1.000000000;
const float p_o8096_scale = 1.000000000;
const float p_o8106_g_0_pos = 0.000000000;
const float p_o8106_g_0_r = 1.000000000;
const float p_o8106_g_0_g = 0.435294002;
const float p_o8106_g_0_b = 0.000000000;
const float p_o8106_g_0_a = 1.000000000;
const float p_o8106_g_1_pos = 1.000000000;
const float p_o8106_g_1_r = 0.000000000;
const float p_o8106_g_1_g = 0.584313989;
const float p_o8106_g_1_b = 0.658824027;
const float p_o8106_g_1_a = 1.000000000;
vec4 o8106_g_gradient_fct(float x) {
  if (x < p_o8106_g_0_pos) {
    return vec4(p_o8106_g_0_r,p_o8106_g_0_g,p_o8106_g_0_b,p_o8106_g_0_a);
  } else if (x < p_o8106_g_1_pos) {
    return mix(vec4(p_o8106_g_0_r,p_o8106_g_0_g,p_o8106_g_0_b,p_o8106_g_0_a), vec4(p_o8106_g_1_r,p_o8106_g_1_g,p_o8106_g_1_b,p_o8106_g_1_a), ((x-p_o8106_g_0_pos)/(p_o8106_g_1_pos-p_o8106_g_0_pos)));
  }
  return vec4(p_o8106_g_1_r,p_o8106_g_1_g,p_o8106_g_1_b,p_o8106_g_1_a);
}
const float p_o8101_scale = 10.000000000;
const float p_o8101_scale_x = 1.000000000;
const float p_o8101_scale_y = 2.000000000;
const float p_o8101_scale_z = 1.000000000;
const float p_o8101_transx = 0.000000000;
const float p_o8101_transy = 0.000000000;
const float p_o8101_transz = 0.000000000;
const float p_o8101_persistence = 0.320000000;
const float p_o8101_brightness = 0.000000000;
const float p_o8101_contrast = 2.000000000;
float o8101_fbm(vec3 coord, float persistence, float _seed_variation_) {
	float normalize_factor = 0.0;
	float value = 0.0;
	float scale = 1.0;
	float size = 1.0;
	for (int i = 0; i < 6; i++) {
		value += XsX3zB_oct_simplex3d(coord*size) * scale;
		normalize_factor += scale;
		size *= 2.0;
		scale *= persistence;
	}
	return value / normalize_factor;
}

float o8101_bc(float f,float contrast, float brightness, float _seed_variation_) {
	return f*contrast+brightness+0.5-contrast*0.5;
}
vec3 o8096_input_BaseColor_tex3d(vec4 p, float _seed_variation_) {
vec3 o8101_0_out = vec3(o8101_bc(o8101_fbm((p).xyz*vec3(p_o8101_scale_x,p_o8101_scale_y,p_o8101_scale_z)*0.5*p_o8101_scale+vec3(p_o8101_transx,p_o8101_transy,p_o8101_transz),p_o8101_persistence, _seed_variation_)*0.5+0.5,p_o8101_contrast,p_o8101_brightness, _seed_variation_));vec3 o8101_0_1_tex3d = clamp(o8101_0_out,vec3(0),vec3(1));
vec3 o8106_0_1_tex3d = o8106_g_gradient_fct(dot(o8101_0_1_tex3d, vec3(1.0))/3.0).rgb;

return o8106_0_1_tex3d;
}
float o8096_input_Metallic_tex3d(vec4 p, float _seed_variation_) {

return 1.0;
}
float o8096_input_Specular_tex3d(vec4 p, float _seed_variation_) {

return 1.0;
}
float o8096_input_Roughness_tex3d(vec4 p, float _seed_variation_) {

return 1.0;
}
vec3 o8096_input_Emission_tex3d(vec4 p, float _seed_variation_) {

return vec3(1.0,1.0,1.0);
}
vec3 o8096_input_Normal_tex3d(vec4 p, float _seed_variation_) {

return vec3(0.0,1.0,0.0);
}
float o8096_input_Alpha_tex3d(vec4 p, float _seed_variation_) {

return 1.0;
}
float o8096_input_AmbientOcclusion_tex3d(vec4 p, float _seed_variation_) {

return 1.0;
}
const float p_o8119_k = 0.150000006;
const float p_o8094_scale = 2.000000000;
const float p_o8094_scale_x = 1.000000000;
const float p_o8094_scale_y = 2.000000000;
const float p_o8094_scale_z = 1.000000000;
const float p_o8094_translate_x = 0.000000000;
const float p_o8094_translate_z = 0.000000000;
const float p_o8094_Distance = 0.007000000;
const float p_o8094_Correction = 3.027000000;
const float p_o8095_r = 1.000000000;
float o8096_input_sdf3d(vec3 p, float _seed_variation_) {
float o8094_0_1_sdf3d = (XsX3zB_simplex3d(((p).xyz+vec3(p_o8094_translate_x,(-o8100_n_rot),p_o8094_translate_z))*vec3(p_o8094_scale_x,p_o8094_scale_y,p_o8094_scale_z)*p_o8094_scale))/(1.0+p_o8094_Correction*p_o8094_scale)-p_o8094_Distance;
float o8095_0_1_sdf3d = length((p))-p_o8095_r;
vec2 o8119_0_1_sdf3dc = sdf3d_smooth_subtraction(vec2(o8094_0_1_sdf3d, 0.0), vec2(o8095_0_1_sdf3d, 0.0), p_o8119_k);

return (o8119_0_1_sdf3dc).x;
}
// 0 - SDF                    (0,0,0,sdf)
// 1 - BaseColor              (r,g,b,sdf) linear (0-1) 
// 2 - Metallic               (v,0,0,sdf)
// 4 - Specular               (v,0,0,sdf)
// 5 - Roughness              (v,0,0,sdf)
//13 - Emission	              (r,g,b,sdf) linear (0-infinite)
//14 - Normal                 (x,y,z,sdf)
//15 - Alpha                  (v,0,0,sdf)
//19 - Ambient Occlusion      (v,0,0,sdf) 
//999 - Table ID - Identifies this table (0,0,0,0)

vec4 PBRObjectMaker_o8096(vec4 uv, float _seed_variation_) {
	float sdf=o8096_input_sdf3d(uv.xyz/p_o8096_scale, _seed_variation_)*p_o8096_scale;
	//19 - Ambient Occlusion
	if (uv.w>18.5) {
		return vec4(p_o8096_AmbientOcclusion*o8096_input_AmbientOcclusion_tex3d(vec4(uv.xyz,19.0), _seed_variation_),0.0,0.0,sdf);
	} else
	//15 - Alpha
	if (uv.w>14.5) {
		return vec4(p_o8096_Alpha*o8096_input_Alpha_tex3d(vec4(uv.xyz,15.0), _seed_variation_),0.0,0.0,sdf);
	} else
	//14 - Normal
	if (uv.w>13.5) {
		return vec4(p_o8096_Normal*o8096_input_Normal_tex3d(vec4(uv.xyz,14.0), _seed_variation_),sdf);
	} else
	//13 - Emission
	if (uv.w>12.5) {
		return vec4(p_o8096_Emission*o8096_input_Emission_tex3d(vec4(uv.xyz,13.0), _seed_variation_),sdf);
	} else
	//5 - Roughness
	if (uv.w>4.5) {
		return vec4(p_o8096_Roughness*o8096_input_Roughness_tex3d(vec4(uv.xyz,5.0), _seed_variation_),0.0,0.0,sdf);
	} else
	//4 - Specular
	if (uv.w>3.5) {
		return vec4(p_o8096_Specular*o8096_input_Specular_tex3d(vec4(uv.xyz,4.0), _seed_variation_),0.0,0.0,sdf);
	} else
	//2 - Metallic
	if (uv.w>1.5) {
		return vec4(p_o8096_Metallic*o8096_input_Metallic_tex3d(vec4(uv.xyz,2.0), _seed_variation_),0.0,0.0,sdf);
	} else
	//1 - BaseColor
	if (uv.w>0.5){
		return vec4(vec4(p_o8096_BaseColor_r, p_o8096_BaseColor_g, p_o8096_BaseColor_b, p_o8096_BaseColor_a).rgb*o8096_input_BaseColor_tex3d(vec4(uv.xyz,1.0), _seed_variation_),sdf);
	} else
	//0 - SDF
	{
		return vec4(vec3(0),sdf);
	}
}vec4 o8093_input_MFSDF(vec4 p, float _seed_variation_) {
vec4 o8096_0_1_v4v4 = PBRObjectMaker_o8096((p), _seed_variation_);

return o8096_0_1_v4v4;
}
vec2 o8092_input_distance(vec3 p, float _seed_variation_) {
float o8093_8_1_sdf3d = o8093_input_MFSDF(vec4((p).xyz,0.0), _seed_variation_).w;

return vec2(o8093_8_1_sdf3d, 0.0);
}
vec3 o8092_input_albedo(vec4 p, float _seed_variation_) {
vec3 o8093_0_1_tex3d = o8093_input_MFSDF(vec4((p).xyz,1.0), _seed_variation_).xyz;

return o8093_0_1_tex3d;
}
vec3 o8092_input_metallic(vec4 p, float _seed_variation_) {
float o8093_1_1_tex3d_gs = o8093_input_MFSDF(vec4((p).xyz,2.0), _seed_variation_).x;

return vec3(o8093_1_1_tex3d_gs);
}
vec3 o8092_input_roughness(vec4 p, float _seed_variation_) {
float o8093_3_1_tex3d_gs = o8093_input_MFSDF(vec4((p).xyz,5.0), _seed_variation_).x;

return vec3(o8093_3_1_tex3d_gs);
}


vec2 GetDist(vec3 p) {
    float _seed_variation_ = seed_variation;

	vec2 d = o8092_input_distance(p, _seed_variation_);

	return d;
}
vec2 RayMarch(vec3 ro, vec3 rd) {
	float dO = 0.0;
	float color = 0.0;
	vec2 dS;
	
	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 p = ro + dO * rd;
		dS = GetDist(p);
		dO += dS.x;
		
		if (dS.x < SURF_DIST || dO > MAX_DIST) {
			color = dS.y;
			break;
		}
	}
	return vec2(dO, color);
}
vec3 GetNormal(vec3 p) {
	vec2 e = vec2(1e-2, 0);
	
	vec3 n = GetDist(p).x - vec3(
		GetDist(p - e.xyy).x,
		GetDist(p - e.yxy).x,
		GetDist(p - e.yyx).x
	);
	
	return normalize(n);
}
void vertex() {
	elapsed_time = TIME;
	world_position = VERTEX;
	world_camera = (inverse(MODELVIEW_MATRIX) * vec4(0, 0, 0, 1)).xyz; //object space
	//world_camera = ( CAMERA_MATRIX  * vec4(0, 0, 0, 1)).xyz; //uncomment this to raymarch in world space
}
void fragment() {
    float _seed_variation_ = seed_variation;
	vec3 ro = world_camera;
	vec3 rd =  normalize(world_position - ro);
	
	vec2 rm  = RayMarch(ro, rd);
	float d = rm.x;
	if (d >= MAX_DIST) {
		discard;
	} else {
		vec3 p = ro + rd * d;

		ALBEDO = o8092_input_albedo(vec4(p, rm.y), _seed_variation_);
		ROUGHNESS = o8092_input_roughness(vec4(p, rm.y), _seed_variation_).x;
		METALLIC = o8092_input_metallic(vec4(p, rm.y), _seed_variation_).x;

		NORMAL = (INV_CAMERA_MATRIX*WORLD_MATRIX*vec4(GetNormal(p), 0.0)).xyz;
	}
}



