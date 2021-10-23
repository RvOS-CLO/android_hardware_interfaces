/**
 * Copyright (c) 2021, The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package android.hardware.graphics.composer3;

import android.hardware.graphics.composer3.Command;

/**
 * The command interface allows composer3 to reduce binder overhead by sending
 * atomic command stream in a command message queue. These commands are usually
 * sent on a per frame basic and contains the information that describes how the
 * display is composited. @see IComposerClient.executeCommands.
 */
@VintfStability
@Backing(type="int")
enum Command {
    LENGTH_MASK = 0xffff,
    OPCODE_SHIFT = 16,
    OPCODE_MASK = 0xffff << OPCODE_SHIFT,

    // special commands

    /**
     * SELECT_DISPLAY has this pseudo prototype
     *
     *   selectDisplay(long display);
     *
     * Selects the current display implied by all other commands.
     *
     * @param display is the newly selected display.
     */
    SELECT_DISPLAY = 0x000 << OPCODE_SHIFT,

    /**
     * SELECT_LAYER has this pseudo prototype
     *
     *   selectLayer(long layer);
     *
     * Selects the current layer implied by all implicit layer commands.
     *
     * @param layer is the newly selected layer.
     */
    SELECT_LAYER = 0x001 << OPCODE_SHIFT,

    // value commands (for return values)

    /**
     * SET_ERROR has this pseudo prototype
     *
     *   setError(uint32_t location, int error);
     *
     * Indicates an error generated by a command.
     *
     * @param location is the offset of the command in the input command
     *        message queue.
     * @param error is the error generated by the command.
     */
    SET_ERROR = 0x100 << OPCODE_SHIFT,

    /**
     * SET_CHANGED_COMPOSITION_TYPES has this pseudo prototype
     *
     *   setChangedCompositionTypes(long[] layers,
     *                              Composition[] types);
     *
     * Sets the layers for which the device requires a different composition
     * type than had been set prior to the last call to VALIDATE_DISPLAY. The
     * client must either update its state with these types and call
     * ACCEPT_DISPLAY_CHANGES, or must set new types and attempt to validate
     * the display again.
     *
     * @param layers is an array of layer handles.
     * @param types is an array of composition types, each corresponding to
     *         an element of layers.
     */
    SET_CHANGED_COMPOSITION_TYPES = 0x101 << OPCODE_SHIFT,

    /**
     * SET_DISPLAY_REQUESTS has this pseudo prototype
     *
     *   setDisplayRequests(int displayRequestMask,
     *                      long[] layers,
     *                      int[] layerRequestMasks);
     *
     * Sets the display requests and the layer requests required for the last
     * validated configuration.
     *
     * Display requests provide information about how the client must handle
     * the client target. Layer requests provide information about how the
     * client must handle an individual layer.
     *
     * @param displayRequestMask is the display requests for the current
     *        validated state.
     * @param layers is an array of layers which all have at least one
     *        request.
     * @param layerRequestMasks is the requests corresponding to each element
     *        of layers.
     */
    SET_DISPLAY_REQUESTS = 0x102 << OPCODE_SHIFT,

    /**
     * SET_PRESENT_FENCE has this pseudo prototype
     *
     *   setPresentFence(int presentFenceIndex);
     *
     * Sets the present fence as a result of PRESENT_DISPLAY. For physical
     * displays, this fence must be signaled at the vsync when the result
     * of composition of this frame starts to appear (for video-mode panels)
     * or starts to transfer to panel memory (for command-mode panels). For
     * virtual displays, this fence must be signaled when writes to the output
     * buffer have completed and it is safe to read from it.
     *
     * @param presentFenceIndex is an index into outHandles array.
     */
    SET_PRESENT_FENCE = 0x103 << OPCODE_SHIFT,

    /**
     * SET_RELEASE_FENCES has this pseudo prototype
     *
     *   setReleaseFences(long[] layers,
     *                    int[] releaseFenceIndices);
     *
     * Sets the release fences for device layers on this display which will
     * receive new buffer contents this frame.
     *
     * A release fence is a file descriptor referring to a sync fence object
     * which must be signaled after the device has finished reading from the
     * buffer presented in the prior frame. This indicates that it is safe to
     * start writing to the buffer again. If a given layer's fence is not
     * returned from this function, it must be assumed that the buffer
     * presented on the previous frame is ready to be written.
     *
     * The fences returned by this function must be unique for each layer
     * (even if they point to the same underlying sync object).
     *
     * @param layers is an array of layer handles.
     * @param releaseFenceIndices are indices into outHandles array, each
     *        corresponding to an element of layers.
     */
    SET_RELEASE_FENCES = 0x104 << OPCODE_SHIFT,

    // display commands

    /**
     * SET_COLOR_TRANSFORM has this pseudo prototype
     *
     *   setColorTransform(float[16] matrix,
     *                     ColorTransform hint);
     *
     * Sets a color transform which will be applied after composition.
     *
     * If hint is not ColorTransform::ARBITRARY, then the device may use the
     * hint to apply the desired color transform instead of using the color
     * matrix directly.
     *
     * If the device is not capable of either using the hint or the matrix to
     * apply the desired color transform, it must force all layers to client
     * composition during VALIDATE_DISPLAY.
     *
     * If IComposer::Capability::SKIP_CLIENT_COLOR_TRANSFORM is present, then
     * the client must never apply the color transform during client
     * composition, even if all layers are being composed by the client.
     *
     * The matrix provided is an affine color transformation of the following
     * form:
     *
     * |r.r r.g r.b 0|
     * |g.r g.g g.b 0|
     * |b.r b.g b.b 0|
     * |Tr  Tg  Tb  1|
     *
     * This matrix must be provided in row-major form:
     *
     * {r.r, r.g, r.b, 0, g.r, ...}.
     *
     * Given a matrix of this form and an input color [R_in, G_in, B_in], the
     * output color [R_out, G_out, B_out] will be:
     *
     * R_out = R_in * r.r + G_in * g.r + B_in * b.r + Tr
     * G_out = R_in * r.g + G_in * g.g + B_in * b.g + Tg
     * B_out = R_in * r.b + G_in * g.b + B_in * b.b + Tb
     *
     * @param matrix is a 4x4 transform matrix (16 floats) as described above.
     * @param hint is a hint value which may be used instead of the given
     *        matrix unless it is ColorTransform::ARBITRARY.
     */
    SET_COLOR_TRANSFORM = 0x200 << OPCODE_SHIFT,

    /**
     * SET_CLIENT_TARGET has this pseudo prototype
     *
     *   setClientTarget(int targetSlot,
     *                   int targetIndex,
     *                   int acquireFenceIndex,
     *                   android.hardware.graphics.common.Dataspace dataspace,
     *                   Rect[] damage);
     *
     * Sets the buffer handle which will receive the output of client
     * composition.  Layers marked as Composition::CLIENT must be composited
     * into this buffer prior to the call to PRESENT_DISPLAY, and layers not
     * marked as Composition::CLIENT must be composited with this buffer by
     * the device.
     *
     * The buffer handle provided may be empty if no layers are being
     * composited by the client. This must not result in an error (unless an
     * invalid display handle is also provided).
     *
     * Also provides a file descriptor referring to an acquire sync fence
     * object, which must be signaled when it is safe to read from the client
     * target buffer.  If it is already safe to read from this buffer, an
     * empty handle may be passed instead.
     *
     * For more about dataspaces, see SET_LAYER_DATASPACE.
     *
     * The damage parameter describes a surface damage region as defined in
     * the description of SET_LAYER_SURFACE_DAMAGE.
     *
     * Will be called before PRESENT_DISPLAY if any of the layers are marked
     * as Composition::CLIENT. If no layers are so marked, then it is not
     * necessary to call this function. It is not necessary to call
     * validateDisplay after changing the target through this function.
     *
     * @param targetSlot is the client target buffer slot to use.
     * @param targetIndex is an index into inHandles for the new target
     *        buffer.
     * @param acquireFenceIndex is an index into inHandles for a sync fence
     *        file descriptor as described above.
     * @param dataspace is the dataspace of the buffer, as described in
     *        setLayerDataspace.
     * @param damage is the surface damage region.
     *
     */
    SET_CLIENT_TARGET = 0x201 << OPCODE_SHIFT,

    /**
     * SET_OUTPUT_BUFFER has this pseudo prototype
     *
     *   setOutputBuffer(int bufferSlot,
     *                   int bufferIndex,
     *                   int releaseFenceIndex);
     *
     * Sets the output buffer for a virtual display. That is, the buffer to
     * which the composition result will be written.
     *
     * Also provides a file descriptor referring to a release sync fence
     * object, which must be signaled when it is safe to write to the output
     * buffer. If it is already safe to write to the output buffer, an empty
     * handle may be passed instead.
     *
     * Must be called at least once before PRESENT_DISPLAY, but does not have
     * any interaction with layer state or display validation.
     *
     * @param bufferSlot is the new output buffer.
     * @param bufferIndex is the new output buffer.
     * @param releaseFenceIndex is a sync fence file descriptor as described
     *        above.
     */
    SET_OUTPUT_BUFFER = 0x202 << OPCODE_SHIFT,

    /**
     * VALIDATE_DISPLAY has this pseudo prototype
     *
     *   validateDisplay();
     *
     * Instructs the device to inspect all of the layer state and determine if
     * there are any composition type changes necessary before presenting the
     * display. Permitted changes are described in the definition of
     * Composition above.
     */
    VALIDATE_DISPLAY = 0x203 << OPCODE_SHIFT,

    /**
     * ACCEPT_DISPLAY_CHANGES has this pseudo prototype
     *
     *   acceptDisplayChanges();
     *
     * Accepts the changes required by the device from the previous
     * validateDisplay call (which may be queried using
     * getChangedCompositionTypes) and revalidates the display. This function
     * is equivalent to requesting the changed types from
     * getChangedCompositionTypes, setting those types on the corresponding
     * layers, and then calling validateDisplay again.
     *
     * After this call it must be valid to present this display. Calling this
     * after validateDisplay returns 0 changes must succeed with NONE, but
     * must have no other effect.
     */
    ACCEPT_DISPLAY_CHANGES = 0x204 << OPCODE_SHIFT,

    /**
     * PRESENT_DISPLAY has this pseudo prototype
     *
     *   presentDisplay();
     *
     * Presents the current display contents on the screen (or in the case of
     * virtual displays, into the output buffer).
     *
     * Prior to calling this function, the display must be successfully
     * validated with validateDisplay. Note that setLayerBuffer and
     * setLayerSurfaceDamage specifically do not count as layer state, so if
     * there are no other changes to the layer state (or to the buffer's
     * properties as described in setLayerBuffer), then it is safe to call
     * this function without first validating the display.
     */
    PRESENT_DISPLAY = 0x205 << OPCODE_SHIFT,

    /**
     * PRESENT_OR_VALIDATE_DISPLAY has this pseudo prototype
     *
     *   presentOrValidateDisplay();
     *
     * Presents the current display contents on the screen (or in the case of
     * virtual displays, into the output buffer) if validate can be skipped,
     * or perform a VALIDATE_DISPLAY action instead.
     */
    PRESENT_OR_VALIDATE_DISPLAY = 0x206 << OPCODE_SHIFT,

    // layer commands (VALIDATE_DISPLAY not required)

    /**
     * SET_LAYER_CURSOR_POSITION has this pseudo prototype
     *
     *   setLayerCursorPosition(int x, int y);
     *
     * Asynchronously sets the position of a cursor layer.
     *
     * Prior to validateDisplay, a layer may be marked as Composition::CURSOR.
     * If validation succeeds (i.e., the device does not request a composition
     * change for that layer), then once a buffer has been set for the layer
     * and it has been presented, its position may be set by this function at
     * any time between presentDisplay and any subsequent validateDisplay
     * calls for this display.
     *
     * Once validateDisplay is called, this function must not be called again
     * until the validate/present sequence is completed.
     *
     * May be called from any thread so long as it is not interleaved with the
     * validate/present sequence as described above.
     *
     * @param layer is the layer to which the position is set.
     * @param x is the new x coordinate (in pixels from the left of the
     *        screen).
     * @param y is the new y coordinate (in pixels from the top of the
     *        screen).
     */
    SET_LAYER_CURSOR_POSITION = 0x300 << OPCODE_SHIFT,

    /**
     * SET_LAYER_BUFFER has this pseudo prototype
     *
     *   setLayerBuffer(int bufferSlot,
     *                  int bufferIndex,
     *                  int acquireFenceIndex);
     *
     * Sets the buffer handle to be displayed for this layer. If the buffer
     * properties set at allocation time (width, height, format, and usage)
     * have not changed since the previous frame, it is not necessary to call
     * validateDisplay before calling presentDisplay unless new state needs to
     * be validated in the interim.
     *
     * Also provides a file descriptor referring to an acquire sync fence
     * object, which must be signaled when it is safe to read from the given
     * buffer. If it is already safe to read from the buffer, an empty handle
     * may be passed instead.
     *
     * This function must return NONE and have no other effect if called for a
     * layer with a composition type of Composition::SOLID_COLOR (because it
     * has no buffer) or Composition::SIDEBAND or Composition::CLIENT (because
     * synchronization and buffer updates for these layers are handled
     * elsewhere).
     *
     * @param layer is the layer to which the buffer is set.
     * @param bufferSlot is the buffer slot to use.
     * @param bufferIndex is the buffer handle to set.
     * @param acquireFenceIndex is a sync fence file descriptor as described above.
     */
    SET_LAYER_BUFFER = 0x301 << OPCODE_SHIFT,

    /*
     * SET_LAYER_SURFACE_DAMAGE has this pseudo prototype
     *
     *   setLayerSurfaceDamage(Rect[] damage);
     *
     * Provides the region of the source buffer which has been modified since
     * the last frame. This region does not need to be validated before
     * calling presentDisplay.
     *
     * Once set through this function, the damage region remains the same
     * until a subsequent call to this function.
     *
     * If damage is non-empty, then it may be assumed that any portion of the
     * source buffer not covered by one of the rects has not been modified
     * this frame. If damage is empty, then the whole source buffer must be
     * treated as if it has been modified.
     *
     * If the layer's contents are not modified relative to the prior frame,
     * damage must contain exactly one empty rect([0, 0, 0, 0]).
     *
     * The damage rects are relative to the pre-transformed buffer, and their
     * origin is the top-left corner. They must not exceed the dimensions of
     * the latched buffer.
     *
     * @param layer is the layer to which the damage region is set.
     * @param damage is the new surface damage region.
     */
    SET_LAYER_SURFACE_DAMAGE = 0x302 << OPCODE_SHIFT,

    // layer state commands (VALIDATE_DISPLAY required)

    /**
     * SET_LAYER_BLEND_MODE has this pseudo prototype
     *
     *   setLayerBlendMode(android.hardware.graphics.common.BlendMode mode)
     *
     * Sets the blend mode of the given layer.
     *
     * @param mode is the new blend mode.
     */
    SET_LAYER_BLEND_MODE = 0x400 << OPCODE_SHIFT,

    /**
     * SET_LAYER_COLOR has this pseudo prototype
     *
     *   setLayerColor(Color color);
     *
     * Sets the color of the given layer. If the composition type of the layer
     * is not Composition::SOLID_COLOR, this call must succeed and have no
     * other effect.
     *
     * @param color is the new color.
     */
    SET_LAYER_COLOR = 0x401 << OPCODE_SHIFT,

    /**
     * SET_LAYER_COMPOSITION_TYPE has this pseudo prototype
     *
     *   setLayerCompositionType(Composition type);
     *
     * Sets the desired composition type of the given layer. During
     * validateDisplay, the device may request changes to the composition
     * types of any of the layers as described in the definition of
     * Composition above.
     *
     * @param type is the new composition type.
     */
    SET_LAYER_COMPOSITION_TYPE = 0x402 << OPCODE_SHIFT,

    /**
     * SET_LAYER_DATASPACE has this pseudo prototype
     *
     *   setLayerDataspace(android.hardware.graphics.common.Dataspace dataspace);
     *
     * Sets the dataspace of the layer.
     *
     * The dataspace provides more information about how to interpret the buffer
     * or solid color, such as the encoding standard and color transform.
     *
     * See the values of Dataspace for more information.
     *
     * @param dataspace is the new dataspace.
     */
    SET_LAYER_DATASPACE = 0x403 << OPCODE_SHIFT,

    /**
     * SET_LAYER_DISPLAY_FRAME has this pseudo prototype
     *
     *   setLayerDisplayFrame(Rect frame);
     *
     * Sets the display frame (the portion of the display covered by a layer)
     * of the given layer. This frame must not exceed the display dimensions.
     *
     * @param frame is the new display frame.
     */
    SET_LAYER_DISPLAY_FRAME = 0x404 << OPCODE_SHIFT,

    /**
     * SET_LAYER_PLANE_ALPHA has this pseudo prototype
     *
     *   setLayerPlaneAlpha(float alpha);
     *
     * Sets an alpha value (a floating point value in the range [0.0, 1.0])
     * which will be applied to the whole layer. It can be conceptualized as a
     * preprocessing step which applies the following function:
     *   if (blendMode == BlendMode::PREMULTIPLIED)
     *       out.rgb = in.rgb * planeAlpha
     *   out.a = in.a * planeAlpha
     *
     * If the device does not support this operation on a layer which is
     * marked Composition::DEVICE, it must request a composition type change
     * to Composition::CLIENT upon the next validateDisplay call.
     *
     * @param alpha is the plane alpha value to apply.
     */
    SET_LAYER_PLANE_ALPHA = 0x405 << OPCODE_SHIFT,

    /**
     * SET_LAYER_SIDEBAND_STREAM has this pseudo prototype
     *
     *   setLayerSidebandStream(int streamIndex)
     *
     * Sets the sideband stream for this layer. If the composition type of the
     * given layer is not Composition::SIDEBAND, this call must succeed and
     * have no other effect.
     *
     * @param streamIndex is the new sideband stream.
     */
    SET_LAYER_SIDEBAND_STREAM = 0x406 << OPCODE_SHIFT,

    /**
     * SET_LAYER_SOURCE_CROP has this pseudo prototype
     *
     *   setLayerSourceCrop(FRect crop);
     *
     * Sets the source crop (the portion of the source buffer which will fill
     * the display frame) of the given layer. This crop rectangle must not
     * exceed the dimensions of the latched buffer.
     *
     * If the device is not capable of supporting a true float source crop
     * (i.e., it will truncate or round the floats to integers), it must set
     * this layer to Composition::CLIENT when crop is non-integral for the
     * most accurate rendering.
     *
     * If the device cannot support float source crops, but still wants to
     * handle the layer, it must use the following code (or similar) to
     * convert to an integer crop:
     *   intCrop.left = (int) ceilf(crop.left);
     *   intCrop.top = (int) ceilf(crop.top);
     *   intCrop.right = (int) floorf(crop.right);
     *   intCrop.bottom = (int) floorf(crop.bottom);
     *
     * @param crop is the new source crop.
     */
    SET_LAYER_SOURCE_CROP = 0x407 << OPCODE_SHIFT,

    /**
     * SET_LAYER_TRANSFORM has this pseudo prototype
     *
     * Sets the transform (rotation/flip) of the given layer.
     *
     *   setLayerTransform(Transform transform);
     *
     * @param transform is the new transform.
     */
    SET_LAYER_TRANSFORM = 0x408 << OPCODE_SHIFT,

    /**
     * SET_LAYER_VISIBLE_REGION has this pseudo prototype
     *
     *   setLayerVisibleRegion(Rect[] visible);
     *
     * Specifies the portion of the layer that is visible, including portions
     * under translucent areas of other layers. The region is in screen space,
     * and must not exceed the dimensions of the screen.
     *
     * @param visible is the new visible region, in screen space.
     */
    SET_LAYER_VISIBLE_REGION = 0x409 << OPCODE_SHIFT,

    /**
     * SET_LAYER_Z_ORDER has this pseudo prototype
     *
     *   setLayerZOrder(int z);
     *
     * Sets the desired Z order (height) of the given layer. A layer with a
     * greater Z value occludes a layer with a lesser Z value.
     *
     * @param z is the new Z order.
     */
    SET_LAYER_Z_ORDER = 0x40a << OPCODE_SHIFT,

    /**
     * SET_PRESENT_OR_VALIDATE_DISPLAY_RESULT has this pseudo prototype
     *
     * setPresentOrValidateDisplayResult(int state);
     *
     * Sets the state of PRESENT_OR_VALIDATE_DISPLAY command.
     * @param state is the state of present or validate
     *    1 - Present Succeeded
     *    0 - Validate succeeded
     */
    SET_PRESENT_OR_VALIDATE_DISPLAY_RESULT = 0x40b << OPCODE_SHIFT,

    /**
     * SET_LAYER_PER_FRAME_METADATA has this pseudo prototype
     *
     *   setLayerPerFrameMetadata(long display, long layer,
     *                            PerFrameMetadata[] data);
     *
     * Sets the PerFrameMetadata for the display. This metadata must be used
     * by the implementation to better tone map content to that display.
     *
     * This is a method that may be called every frame. Thus it's
     * implemented using buffered transport.
     * SET_LAYER_PER_FRAME_METADATA is the command used by the buffered transport
     * mechanism.
     */
    SET_LAYER_PER_FRAME_METADATA = 0x303 << OPCODE_SHIFT,

    /**
     * SET_LAYER_FLOAT_COLOR has this pseudo prototype
     *
     *   setLayerColor(FloatColor color);
     *
     * Sets the color of the given layer. If the composition type of the layer
     * is not Composition::SOLID_COLOR, this call must succeed and have no
     * other effect.
     *
     * @param color is the new color using float type.
     */
    SET_LAYER_FLOAT_COLOR = 0x40c << OPCODE_SHIFT,

    /**
     * SET_LAYER_COLOR_TRANSFORM has this pseudo prototype
     *
     *   setLayerColorTransform(float[16] matrix);
     *
     * This command has the following binary layout in bytes:
     *
     *     0 - 16 * 4: matrix
     *
     * Sets a matrix for color transform which will be applied on this layer
     * before composition.
     *
     * If the device is not capable of apply the matrix on this layer, it must force
     * this layer to client composition during VALIDATE_DISPLAY.
     *
     * The matrix provided is an affine color transformation of the following
     * form:
     *
     * |r.r r.g r.b 0|
     * |g.r g.g g.b 0|
     * |b.r b.g b.b 0|
     * |Tr  Tg  Tb  1|
     *
     * This matrix must be provided in row-major form:
     *
     * {r.r, r.g, r.b, 0, g.r, ...}.
     *
     * Given a matrix of this form and an input color [R_in, G_in, B_in],
     * the input color must first be converted to linear space
     * [R_linear, G_linear, B_linear], then the output linear color
     * [R_out_linear, G_out_linear, B_out_linear] will be:
     *
     * R_out_linear = R_linear * r.r + G_linear * g.r + B_linear * b.r + Tr
     * G_out_linear = R_linear * r.g + G_linear * g.g + B_linear * b.g + Tg
     * B_out_linear = R_linear * r.b + G_linear * g.b + B_linear * b.b + Tb
     *
     * [R_out_linear, G_out_linear, B_out_linear] must then be converted to
     * gamma space: [R_out, G_out, B_out] before blending.
     *
     * @param matrix is a 4x4 transform matrix (16 floats) as described above.
     */

    SET_LAYER_COLOR_TRANSFORM = 0x40d << OPCODE_SHIFT,
    /*
     * SET_LAYER_PER_FRAME_METADATA_BLOBS has this pseudo prototype
     *
     *   setLayerPerFrameMetadataBlobs(long display, long layer,
     *                                   PerFrameMetadataBlob[] metadata);
     *
     *   This command sends metadata that may be used for tone-mapping the
     *   associated layer.  The metadata structure follows a {key, blob}
     *   format (see the PerFrameMetadataBlob struct).  All keys must be
     *   returned by a prior call to getPerFrameMetadataKeys and must
     *   be part of the list of keys associated with blob-type metadata
     *   (see PerFrameMetadataKey).
     *
     *   This method may be called every frame.
     */
    SET_LAYER_PER_FRAME_METADATA_BLOBS = 0x304 << OPCODE_SHIFT,

    /**
     * SET_CLIENT_TARGET_PROPERTY has this pseudo prototype
     *
     * This command has the following binary layout in bytes:
     *
     *     0 - 3: clientTargetProperty.pixelFormat
     *     4 - 7: clientTargetProperty.dataspace
     *
     *   setClientTargetProperty(ClientTargetProperty clientTargetProperty);
     */
    SET_CLIENT_TARGET_PROPERTY = 0x105 << OPCODE_SHIFT,

    /**
     * SET_LAYER_GENERIC_METADATA has this pseudo prototype
     *
     *   setLayerGenericMetadata(string key, bool mandatory, byte[] value);
     *
     * Sets a piece of generic metadata for the given layer. If this
     * function is called twice with the same key but different values, the
     * newer value must override the older one. Calling this function with a
     * 0-length value must reset that key's metadata as if it had not been
     * set.
     *
     * A given piece of metadata may either be mandatory or a hint
     * (non-mandatory) as indicated by the second parameter. Mandatory
     * metadata may affect the composition result, which is to say that it
     * may cause a visible change in the final image. By contrast, hints may
     * only affect the composition strategy, such as which layers are
     * composited by the client, but must not cause a visible change in the
     * final image. The value of the mandatory flag shall match the value
     * returned from getLayerGenericMetadataKeys for the given key.
     *
     * Only keys which have been returned from getLayerGenericMetadataKeys()
     * shall be accepted. Any other keys must result in an UNSUPPORTED error.
     *
     * The value passed into this function shall be the binary
     * representation of a HIDL type corresponding to the given key. For
     * example, a key of 'com.example.V1_3.Foo' shall be paired with a
     * value of type com.example@1.3::Foo, which would be defined in a
     * vendor HAL extension.
     *
     * This function will be encoded in the command buffer in this order:
     *   1) The key length, stored as a uint32_t
     *   2) The key itself, padded to a uint32_t boundary if necessary
     *   3) The mandatory flag, stored as a uint32_t
     *   4) The value length in bytes, stored as a uint32_t
     *   5) The value itself, padded to a uint32_t boundary if necessary
     *
     * @param key indicates which metadata value should be set on this layer
     * @param mandatory indicates whether this particular key represents
     *        mandatory metadata or a hint (non-mandatory metadata), as
     *        described above
     * @param value is a binary representation of a HIDL struct
     *        corresponding to the key as described above
     */
    SET_LAYER_GENERIC_METADATA = 0x40e << OPCODE_SHIFT,
}
