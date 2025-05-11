import SwiftUI

struct RecurringTasksView: View {
    @EnvironmentObject var recurringManager: RecurringTaskManager
    @EnvironmentObject var groupManager: TaskGroupManager

    @State private var showAddRecurring = false
    @State private var selectedFilter: RecurringInterval? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.85, green: 0.9, blue: 1.0),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Recurring Tasks")
                        .font(.largeTitle.bold())
                        .padding(.top)

                    filterButtons

                    if filteredTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("No Recurring Tasks")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredTasks.indices, id: \.self) { index in
                                    let task = filteredTasks[index]
                                    NavigationLink(destination: RecurringTaskDetailView(task: task, taskIndex: index)
                                        .environmentObject(recurringManager)) {
                                        recurringTaskCard(task)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddRecurring = true
                    } label: {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showAddRecurring) {
                NewRecurringTaskView()
                    .environmentObject(recurringManager)
                    .environmentObject(groupManager)
            }
        }
    }

    private var filterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterButton(title: "All", type: nil)
                filterButton(title: "Daily", type: .daily)
                filterButton(title: "Weekly", type: .weekly)
                filterButton(title: "Monthly", type: .monthly)
                filterButton(title: "Yearly", type: .yearly)
            }
            .padding(.horizontal)
        }
    }

    private func filterButton(title: String, type: RecurringInterval?) -> some View {
        Button(action: {
            selectedFilter = type
        }) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(selectedFilter == type ? .white : .accentColor)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(
                    selectedFilter == type
                    ? Color.accentColor
                    : Color.clear
                )
                .overlay(
                    Capsule()
                        .stroke(Color.accentColor, lineWidth: 1.5)
                )
                .clipShape(Capsule())
        }
    }

    private func recurringTaskCard(_ task: RecurringTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title)
                .font(.headline)
                .foregroundColor(.primary)

            if task.isTimeSensitive {
                switch task.timeSensitivityType {
                case .dueBy:
                    if let dueBy = task.exactTime {
                        Text("\(task.recurringInterval.rawValue) • Due by \(dueBy.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                case .startsAt:
                    if let startsAt = task.exactTime {
                        Text("\(task.recurringInterval.rawValue) • Starts at \(startsAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                case .busyFromTo:
                    if let start = task.timeRangeStart, let end = task.timeRangeEnd {
                        Text("\(task.recurringInterval.rawValue) • \(start.formatted(date: .omitted, time: .shortened))–\(end.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                case .none:
                    EmptyView()
                }
            } else {
                Text(task.recurringInterval.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 4)
        )
    }

    private var filteredTasks: [RecurringTask] {
        if let filter = selectedFilter {
            return recurringManager.tasks.filter { $0.recurringInterval == filter }
        } else {
            return recurringManager.tasks
        }
    }

    private func deleteRecurringTask(at offsets: IndexSet) {
        let mappedOffsets = IndexSet(offsets.map { index in
            recurringManager.tasks.firstIndex(where: { $0.id == filteredTasks[index].id }) ?? index
        })
        recurringManager.tasks.remove(atOffsets: mappedOffsets)
    }
}
