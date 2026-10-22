import { RequestsView } from "@/components/dashboard/requests-view";
import { getDashboardData } from "@/lib/queries";

export default async function RequestsPage() {
  const data = await getDashboardData();
  if (!data) return null;
  return <RequestsView reservations={data.reservations} />;
}
