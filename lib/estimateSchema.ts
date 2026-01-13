import { z } from "zod";

export const estimateResultSchema = z.object({
  cubicFeet: z.number().int().min(0),
  truck: z.enum(["10ft", "16ft", "20ft", "26ft"]),
  movers: z.union([z.literal(2), z.literal(3), z.literal(4)]),
  laborHours: z.number().min(0),
  packingMaterials: z.object({
    boxes: z.number().int().min(0).optional(),
    tape: z.number().int().min(0).optional(),
    bubbleWrap: z.number().int().min(0).optional(),
    furniturePads: z.number().int().min(0).optional(),
  }),
  confidence: z.enum(["low", "medium", "high"]),
  explanationBullets: z.array(z.string()).max(5).optional(),
});

export type EstimateResult = z.infer<typeof estimateResultSchema>;

