//!DESC Anime4K-v4.0-ForceDownscalePre-x2
//!HOOK MAIN
//!BIND HOOKED
//!WIDTH HOOKED_size.x / 2.0
//!HEIGHT HOOKED_size.y / 2.0

vec4 hook() {
    return HOOKED_tex(HOOKED_pos);
}
