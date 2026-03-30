using System;
using System.IO;
using Microsoft.EntityFrameworkCore;
using ArtTimeTracker.Core.Models;

namespace ArtTimeTracker.Core.Data;

public class AppDbContext : DbContext
{
    public DbSet<Artwork> Artworks => Set<Artwork>();
    public DbSet<TrackingSession> Sessions => Set<TrackingSession>();

    private static string DbPath
    {
        get
        {
            var folder = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "ArtTimeTracker");
            Directory.CreateDirectory(folder);
            return Path.Combine(folder, "arttimetracker.db");
        }
    }

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        options.UseSqlite($"Data Source={DbPath}");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<TrackingSession>()
            .HasOne(s => s.Artwork)
            .WithMany(a => a.Sessions)
            .HasForeignKey(s => s.ArtworkId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
