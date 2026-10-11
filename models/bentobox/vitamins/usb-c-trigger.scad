// SPDX-FileCopyrightText: 2026 Alon A. Rabinowitz
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
// A remix of BentoBox v2.0 by ThrutheFrame (https://www.printables.com/model/272525), CC BY-NC-SA 4.0.

// vitamins/usb-c-trigger.scad - THE USB-C PD TRIGGER BOARD, as Alon measured it (Q134): its numbers, and its model for the checks. Included by bentobox.scad; not a model on its own.

/* [The USB-C trigger board, as measured] */
// The box takes 12 V from a USB-C charger through a PD trigger board ("USB-C PD3.0/3.1 QC3.0 trigger
// board", its low-voltage variant), MEASURED by Alon, 9 Oct 2026 (Q134): the socket stands on the board and past its edge, nothing
// is under the board, and its + and - pads are at the far corners. A step-down feeds the ESP32 from the 12 V.
usb_board  = [14.51, 9.97, 1.05];   /* The board: its whole length, from the socket's face to the far edge; its width; its thickness... */
usb_socket = [8.96, 3.25, 1.55];    /* ...the socket: its width, its height, and how far it stands past the board's edge... */
usb_parts_h = 0.74;     /* ...and the tallest part on the board but the socket. */
/* [Hidden] */

// The USB-C board as Alon measured it: the board, the socket on it standing past its edge, and its parts - held sep
// off the wall in front of it and the pocket's floor, as it sits. A control moves it (usb_shift).
module usb_board_model() translate(usb_shift + [usb_x, 0, 0]) {
    translate([-usb_board[1] / 2, usb_pcb_y0 + sep, usb_pcb_z + sep]) cube([usb_board[1], usb_board[0] - usb_socket[2], usb_board[2]]);
    hull() for (s = [-1, 1]) translate([s * (usb_socket[0] - usb_socket[1]) / 2, -bb_l / 2 + sep, usb_axis_z + sep])
        rotate([-90, 0, 0]) cylinder(d = usb_socket[1], h = 7.5, $fn = 32);
    translate([-usb_board[1] / 2 + 1, -bb_l / 2 + 8, usb_pcb_z + usb_board[2] + sep]) cube([usb_board[1] - 2, usb_board[0] - 9, usb_parts_h]);
}
