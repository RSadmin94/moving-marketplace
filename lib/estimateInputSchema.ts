import { z } from "zod";

// Schema for POST /api/estimate input
export const estimateInputSchema = z.object({
  jobId: z.string().optional(),
  inputData: z.object({
    moveType: z.enum(["APT", "HOUSE", "OFFICE"]).optional(),
    bedrooms: z.number().int().min(0).optional(),
    stairs: z.boolean().optional(),
    elevator: z.boolean().optional(),
    distanceMiles: z.number().int().min(0).optional(),
    moveDate: z.string().optional(),
  }),
  photoData: z.union([
    z.array(z.string()), // Array of photo URLs
    z.object({
      photos: z.array(z.object({
        url: z.string(),
        width: z.number().optional(),
        height: z.number().optional(),
      })),
    }),
  ]),
  aiResult: z.object({
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
  }),
});

export type EstimateInput = z.infer<typeof estimateInputSchema>;

