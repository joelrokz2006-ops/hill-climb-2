# VEHICLE TUNING CHANGELOG

This document tracks all physical tuning adjustments made to the Hill Climb 2D vehicle fleet.

---

## 1. Physics Tuning Comparison Table

| Vehicle Variant | Parameter | Baseline (Before) | Tuned (After) | Physical Justification / Gameplay Effect |
|---|---|---|---|---|
| **Classic Hill Climber** (Lvl 1) | `base_motor_torque` | `18,000.0 Nm` | `75,000.0 Nm` | Overcomes $4,357\text{ N}$ gravitational resistance on $20^\circ$ slopes with $+170\text{ px/s}^2$ steady climb. |
| **Classic Hill Climber** (Lvl 1) | `base_brake_torque` | `12,000.0 Nm` | `45,000.0 Nm` | Provides reliable hill-holding and quick stopping power on descents. |
| **Classic Hill Climber** (Lvl 1) | `max_wheel_speed` | `80.0 rad/s` (hard cutoff) | `80.0 rad/s` (smooth taper) | Tapers drive torque linearly over the upper 25% of max speed to eliminate chatter and uncontrolled wheel spin. |
| **Classic Hill Climber** (Lvl 1) | `base_wheel_friction` | `1.60` | `1.60` | Maintained for baseline tire grip. Upgrades scale up to `3.01` at Level 5. |
| **Classic Hill Climber** (Lvl 1) | `base_suspension_softness` | `0.60` | `0.60` | Dual PinJoint2D suspension damping firming down to `0.28` at Level 5. |
| **Monster Truck** (Heavy) | `base_motor_torque` | `28,000.0 Nm` | `135,000.0 Nm` | Compensates for heavy $14.0\text{ kg}$ chassis and high center of mass; climbs aggressive inclines. |
| **Monster Truck** (Heavy) | `base_brake_torque` | `16,000.0 Nm` | `80,000.0 Nm` | Proportional braking for heavy monster truck chassis. |
| **Dune Buggy** (Electric Agile) | `base_motor_torque` | `19,000.0 Nm` | `60,000.0 Nm` | Lightweight $7.0\text{ kg}$ chassis accelerates swiftly without instant backflipping. |
| **Dune Buggy** (Electric Agile) | `base_brake_torque` | `13,000.0 Nm` | `35,000.0 Nm` | Smooth regenerative braking. |
| **All Vehicles** | Landing Trauma Shake | None | Clamped trauma $\le 7\text{ px}$ | Adds responsive camera screen shake on hard landing and crashes. |
| **All Vehicles** | Clean Landing Bonus | None | $+5\text{ Coins}$ reward | Encourages smooth, level landings from high-altitude jumps. |

---

## 2. Dynamic Upgrades Formulae (Preserved)

All vehicle upgrades dynamically modify base values using the formulas below:

- **Engine Power (`engine_level` 1–5):**
  $$\text{motor\_torque} = \text{base\_motor\_torque} \times [1.0 + (\text{level} - 1) \times 0.20]$$
  $$\text{brake\_torque} = \text{base\_brake\_torque} \times [1.0 + (\text{level} - 1) \times 0.15]$$
  $$\text{max\_wheel\_speed} = \text{base\_max\_wheel\_speed} \times [1.0 + (\text{level} - 1) \times 0.12]$$

- **Tire Grip (`grip_level` 1–5):**
  $$\text{friction} = \text{base\_wheel\_friction} \times [1.0 + (\text{level} - 1) \times 0.22]$$

- **Suspension (`suspension_level` 1–5):**
  $$\text{softness} = \max(0.18, \text{base\_suspension\_softness} - (\text{level} - 1) \times 0.08)$$

- **Fuel Tank (`fuel_tank_level` 1–5):**
  $$\text{max\_fuel} = \text{base\_max\_fuel} \times [1.0 + (\text{level} - 1) \times 0.25]$$
