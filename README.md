# DVR Decode


The purpose of this experiment is to extract video footage from a generic "H.264 Recorder".
A lot of these seem to be made by Dahua, but are branded with different names.

Normally you can play the recordings on the device itself and export individual clips.
As luck would have it, I've ended up with a malfunctioning unit that refused to play the recorded video.

It appeared to record normally judging by the status LED and the decreasing free space.
At this point I had to put my detective hat on. Challenge accepted.

## Obtaining raw data

The disk layout consists of two partitions.

    Disk /dev/sdd: 232,9 GiB, 250059350016 bytes, 488397168 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0x00000000

    Device     Boot   Start       End   Sectors  Size Id Type
    /dev/sdd1            63   6008309   6008247  2,9G  c W95 FAT32 (LBA)
    /dev/sdd2       6008310 488392064 482383755  230G 83 Linux

The raw video data is located on the second, larger partition.

I didn't bother to look at the first partition at this point.

Lets image the HDD using dd:

    dd if=/dev/sdd2 of=dvr.raw bs=128k

## Analysis

The device seems to use the HDD much like a tape.

Once a camera starts recording it creates a block starting with XXdcH264 where XX is the channel identifier, e.g. 03dcH264.
A recoding usually consists of multiple blocks. Simultaneous recordings are interleaved.

This is how a block looks like:

    001f060: bf9a 5c7f 88f1 3700 3330 6463 4832 3634  ..\...7.30dcH264   <-- ID "30", delimiter "dcH264"
    001f070: 82dd 0000 0800 2000 0c7d a129 9e02 0000  ...... ..}.)....
    001f080: 0e0a 1501 2708 0000 0000 0001 6742 e015  ....'.......gB..   <-- 0000 0000 0001 is a NAL unit
    001f090: db02 c094 4000 0000 0168 ce30 a480 0000  ....@....h.0....
    001f0a0: 0001 06e5 012f 8000 0000 0165 b800 0d73  ...../.....e...s

It contains a preamble of sorts that I'm not able to decode at this point.
What follow is a H.264 [Network Abstraction Layer (NAL) unit](http://en.wikipedia.org/wiki/Network_Abstraction_Layer).

Let's fire up [h264_analyze](https://github.com/aizvorski/h264bitstream) to find out what's lurking in there.

    !! Found NAL at offset 127116 (0x1F08C), size 9 (0x0009)
    0.8: forbidden_zero_bit: 0
    0.7: nal->nal_ref_idc: 3
    0.5: nal->nal_unit_type: 7
    1.8: sps->profile_idc: 66
    2.8: sps->constraint_set0_flag: 1
    2.7: sps->constraint_set1_flag: 1
    2.6: sps->constraint_set2_flag: 1
    2.5: sps->constraint_set3_flag: 0
    2.4: sps->constraint_set4_flag: 0
    2.3: sps->constraint_set5_flag: 0
    2.2: reserved_zero_2bits: 0
    3.8: sps->level_idc: 21
    4.8: sps->seq_parameter_set_id: 0
    4.7: sps->log2_max_frame_num_minus4: 0
    4.6: sps->pic_order_cnt_type: 2
    4.3: sps->num_ref_frames: 2
    5.8: sps->gaps_in_frame_num_value_allowed_flag: 0
    5.7: sps->pic_width_in_mbs_minus1: 43
    6.4: sps->pic_height_in_map_units_minus1: 17
    7.3: sps->frame_mbs_only_flag: 1
    7.2: sps->direct_8x8_inference_flag: 0
    7.1: sps->frame_cropping_flag: 0
    8.8: sps->vui_parameters_present_flag: 0
    8.7: rbsp_stop_one_bit: 1

That's a Sequence Parameter Set (NAL type 7), usually indicating the start of a video stream.
It's followed by a Picture Parameter Set (NAL type 8):

    !! Found NAL at offset 127129 (0x1F099), size 5 (0x0005)
    0.8: forbidden_zero_bit: 0
    0.7: nal->nal_ref_idc: 3
    0.5: nal->nal_unit_type: 8
    1.8: pps->pic_parameter_set_id: 0
    1.7: pps->seq_parameter_set_id: 0
    1.6: pps->entropy_coding_mode_flag: 0
    1.5: pps->pic_order_present_flag: 0
    1.4: pps->num_slice_groups_minus1: 0
    1.3: pps->num_ref_idx_l0_active_minus1: 0
    1.2: pps->num_ref_idx_l1_active_minus1: 0
    1.1: pps->weighted_pred_flag: 0
    2.8: pps->weighted_bipred_idc: 0
    2.6: pps->pic_init_qp_minus26: 0
    2.5: pps->pic_init_qs_minus26: 0
    2.4: pps->chroma_qp_index_offset: 10
    3.3: pps->deblocking_filter_control_present_flag: 1
    3.2: pps->constrained_intra_pred_flag: 0
    3.1: pps->redundant_pic_cnt_present_flag: 0
    4.8: rbsp_stop_one_bit: 1

Next is a Supplemental Enhancement Information (NAL type 6) block that doesn't seem to contain useful information.
What follows is the actual frames:

    !! Found NAL at offset 127147 (0x1F0AB), size 56671 (0xDD5F)
    0.8: forbidden_zero_bit: 0
    0.7: nal->nal_ref_idc: 3
    0.5: nal->nal_unit_type: 5
    1.8: sh->first_mb_in_slice: 0
    1.7: sh->slice_type: 2
    1.4: sh->pic_parameter_set_id: 0
    1.3: sh->frame_num: 0
    2.7: sh->idr_pic_id: 3442
    5.8: sh->drpm.no_output_of_prior_pics_flag: 0
    5.7: sh->drpm.long_term_reference_flag: 0
    5.6: sh->slice_qp_delta: -8
    6.5: sh->disable_deblocking_filter_idc: 0
    6.4: sh->slice_alpha_c0_offset_div2: 5
    7.5: sh->slice_beta_offset_div2: 5

    !! Found NAL at offset 183852 (0x2CE2C), size 4295 (0x10C7)
    0.8: forbidden_zero_bit: 0
    0.7: nal->nal_ref_idc: 3
    0.5: nal->nal_unit_type: 1
    1.8: sh->first_mb_in_slice: 0
    1.7: sh->slice_type: 0
    1.6: sh->pic_parameter_set_id: 0
    1.5: sh->frame_num: 1
    1.1: sh->num_ref_idx_active_override_flag: 0
    2.8: sh->rplr.ref_pic_list_reordering_flag_l0: 0
    2.7: sh->drpm.adaptive_ref_pic_marking_mode_flag: 0
    2.6: sh->slice_qp_delta: 6
    3.7: sh->disable_deblocking_filter_idc: 0
    3.6: sh->slice_alpha_c0_offset_div2: 5
    4.7: sh->slice_beta_offset_div2: 5

So far so good. If we manage to extract the streams into separate files we should be all set.
