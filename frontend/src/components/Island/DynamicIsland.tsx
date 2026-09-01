import { Label } from "../../ui"
import { ChevronDown } from "lucide-react"

export default function DynamicIsland () {
  return <div className="mx-auto w-full max-w-6xl justify-between p-8 shadow-md rounded-4xl bg-white hover:shadow-xl border-gray-200 flex items-center">
    <button aria-haspopup className="flex flex-col gap-2">
      <Label>going to</Label>
      <div className="flex items-center gap-2">
        <span className="text-base font-semibold">Ticao</span>
        <ChevronDown className="text-venice" size={15} />
      </div>
    </button>
    <button aria-haspopup className="flex flex-col gap-2">
      <Label>going to</Label>
      <div className="flex items-center gap-2">
        <span className="text-base font-semibold">Ticao</span>
        <ChevronDown className="text-venice" size={15} />
      </div>
    </button>
  </div>
}