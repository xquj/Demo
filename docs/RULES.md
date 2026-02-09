# Gloomtable Rules

## Turn Order
1. **Draw Phase** – Active player draws 1 card.
2. **Play Phase** – Active player plays cards from hand if costs are paid. Spells resolve instantly.
3. **Combat Phase** – Player units attack, then enemy units attack.
4. **Resolution Phase** – Damage is applied and defeated units die.
5. **End Phase** – Check win condition, then the next player starts their turn.

## Costs
- **Blood**: Sacrifice that many friendly units on the board to play the card.
- **Bone**: Spend bones accumulated from unit deaths.

## Combat Resolution
- A unit attacks the opposing lane.
- If a defender exists, it takes damage equal to the attacker's attack.
- If the opposing lane is empty, damage goes directly to the **Balance Scale**.
- Units reduced to 0 health die and grant their owner **+1 bone**.

## Ability Trigger Order
Abilities are data-driven and hook into events:
- **on_play**: After a unit is placed on the board.
- **on_attack**: Before a unit deals damage.
- **on_hit**: After damage is dealt (blocked or direct).
- **on_death**: When a unit dies.
- **on_turn_start**: When the owner's turn begins.

## Win Condition
- The **Balance Scale** starts at 0.
- When it reaches **+10**, the player wins.
- When it reaches **-10**, the enemy wins.
