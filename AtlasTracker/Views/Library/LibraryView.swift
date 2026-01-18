import SwiftUI

struct LibraryView: View {
    @State private var viewModel = LibraryViewModel()
    @State private var showAddCompound = false
    @State private var selectedCompound: Compound?
    var onClose: (() -> Void)?

    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    SearchBarView(text: $viewModel.searchText, placeholder: "Search compounds...")
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Category filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryFilterChip(
                                category: nil,
                                isSelected: viewModel.selectedCategory == nil
                            ) {
                                viewModel.selectedCategory = nil
                            }

                            ForEach(CompoundCategory.allCases, id: \.self) { category in
                                CategoryFilterChip(
                                    category: category,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)

                    // Sort options
                    HStack {
                        Text("\(viewModel.filteredCompounds.count) compounds")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Spacer()

                        Menu {
                            ForEach(CompoundSortOption.allCases, id: \.self) { option in
                                Button {
                                    viewModel.sortOption = option
                                } label: {
                                    Label(option.rawValue, systemImage: option.icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.sortOption.icon)
                                Text(viewModel.sortOption.rawValue)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .font(.caption)
                            .foregroundColor(.accentPrimary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    // Compound list
                    if viewModel.filteredCompounds.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Compounds Found",
                            message: viewModel.searchText.isEmpty
                                ? "No compounds in this category"
                                : "Try a different search term"
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.filteredCompounds, id: \.id) { compound in
                                    NavigationLink(value: compound) {
                                        CompoundListRow(compound: compound) {
                                            viewModel.toggleFavorite(compound)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let onClose = onClose {
                        Button {
                            onClose()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentPrimary)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddCompound = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Compound.self) { compound in
                CompoundDetailView(compound: compound)
            }
            .sheet(isPresented: $showAddCompound) {
                AddCustomCompoundView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadCompounds()
            }
        }
    }
}

#Preview {
    LibraryView()
        .preferredColorScheme(.dark)
}
