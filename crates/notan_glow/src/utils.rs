#[cfg(target_arch = "wasm32")]
use wasm_bindgen::JsCast;

#[cfg(target_arch = "wasm32")]
pub(crate) fn create_gl_context(
    win: &web_sys::HtmlCanvasElement,
    antialias: bool,
    transparent: bool,
) -> Result<(glow::Context, String), String> {
    if let Ok(ctx) = create_webgl2_context(win, antialias, transparent) {
        return Ok((ctx, "webgl2".to_string()));
    }

    let ctx = create_webgl_context(win, antialias, transparent)?;
    Ok((ctx, "webgl".to_string()))
}

#[cfg(target_arch = "wasm32")]
fn webgl_options(antialias: bool, transparent: bool) -> web_sys::WebGlContextAttributes {
    let mut opts = web_sys::WebGlContextAttributes::new();
    opts.stencil(true);
    opts.premultiplied_alpha(false);
    opts.alpha(transparent);
    opts.antialias(antialias);
    opts
}

#[cfg(target_arch = "wasm32")]
fn create_webgl_context(
    win: &web_sys::HtmlCanvasElement,
    antialias: bool,
    transparent: bool,
) -> Result<glow::Context, String> {
    //TODO manage errors
    let gl = win
        .get_context_with_context_options("webgl", webgl_options(antialias, transparent).as_ref())
        .map_err(|e| format!("Failed to create WebGL context: {e:?}"))?
        .ok_or_else(|| format!("Failed to create WebGL context"))?
        .dyn_into::<web_sys::WebGlRenderingContext>()
        .map_err(|e| format!("Failed to cast the context to WebGL context: {e:?}"))?;

    let ctx = glow::Context::from_webgl1_context(gl);
    Ok(ctx)
}

#[cfg(target_arch = "wasm32")]
fn create_webgl2_context(
    win: &web_sys::HtmlCanvasElement,
    antialias: bool,
    transparent: bool,
) -> Result<glow::Context, String> {
    //TODO manage errors
    let gl = win
        .get_context_with_context_options("webgl2", webgl_options(antialias, transparent).as_ref())
        .map_err(|e| format!("Failed to create WebGL2 context: {e:?}"))?
        .ok_or_else(|| format!("Failed to create WebGL2 context"))?
        .dyn_into::<web_sys::WebGl2RenderingContext>()
        .map_err(|e| format!("Failed to cast the context to WebGL2 context: {e:?}"))?;

    let ctx = glow::Context::from_webgl2_context(gl);
    Ok(ctx)
}
