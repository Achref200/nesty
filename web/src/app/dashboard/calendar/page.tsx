import { MonthCalendar } from "@/components/dashboard/month-calendar";
import { getDashboardData } from "@/lib/queries";

export default async function CalendarPage() {
  const data = await getDashboardData();
  if (!data) return null;
  return <MonthCalendar reservations={data.reservations} />;
}
