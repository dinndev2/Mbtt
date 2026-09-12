import { WavesHorizontal, Building, Leaf } from "lucide-react"

export function titleize(str: string | undefined ) {
  if(str == undefined || str == "") return "Text"
  return str.replace(/\b\w/g, char => char.toUpperCase())
}

export function CategoryLogo(str: string, size=13) {
  switch(str) {
    case "Sea":
      return <WavesHorizontal size={size} />
    case "City":
      return <Building size={size} />
    case "Nature":
      return <Leaf size={size} />
    default:
      return <WavesHorizontal size={size} />
  }
}